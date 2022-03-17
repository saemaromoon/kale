NS=$(kubectl describe serviceaccount default | grep Namespace | sed "s/ //g"| sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["Namespace"])}' 2>&1)
TOKEN=$(kubectl describe serviceaccount default | grep Tokens | sed "s/ //g"| sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["Tokens"])}' 2>&1)
VALUE=$(kubectl describe secret ${TOKEN} | grep token: | sed "s/ //g" | sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["token"])}' 2>&1)
OWNER=$(kubectl get ns ${NS} -o yaml | grep owner: | sed -n 1p | sed "s/ //g"| sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["owner"])}' 2>&1)

sudo mkdir -p /var/run/secrets/kubeflow/pipelines

echo "Setting access token: \n"
echo $VALUE | sudo tee /var/run/secrets/kubeflow/pipelines/token

echo "Settings namespace context \n"
sudo mkdir -p /home/jovyan/.config/kfp
echo "{\"namespace\":\"$NS\"}" | sudo tee /home/jovyan/.config/kfp/context.json

NOTEBOOK=$(cat /etc/hostname | sed 's/-[^-]*$//' 2>&1)
echo "Notebook name: $NOTEBOOK"

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: add-header-$NS-$NOTEBOOK
  namespace: $NS
spec:
  configPatches:
  - applyTo: VIRTUAL_HOST
    match:
      context: SIDECAR_OUTBOUND
      routeConfiguration:
        vhost:
          name: ml-pipeline.kubeflow.svc.cluster.local:8888
          route:
            name: default
    patch:
      operation: MERGE
      value:
        request_headers_to_add:
        - append: true
          header:
            key: kubeflow-userid
            value: $OWNER
  workloadSelector:
    labels:
      notebook-name: $NOTEBOOK #your notebook
EOF
echo "Applied Envoy Filter"

cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: bind-ml-pipeline-$NOTEBOOK-$NS
 namespace: kubeflow
spec:
 selector:
   matchLabels:
     app: ml-pipeline
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/$NS/sa/default-editor"]
EOF
echo "Applied AuthorizationPolicy"