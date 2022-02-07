NS=$(kubectl describe serviceaccount default | grep Namespace | sed "s/ //g"| sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["Namespace"])}' 2>&1)
TOKEN=$(kubectl describe serviceaccount default | grep Tokens | sed "s/ //g"| sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["Tokens"])}' 2>&1)
VALUE=$(kubectl describe secret ${TOEKN} | grep token: | sed "s/ //g" | sed -r 's/[:]+/=/g'| awk -F= '{a[$1]=$2} END {print(a["token"])}' 2>&1)

sudo mkdir -p /var/run/secrets/kubeflow/pipelines
echo $VALUE | sudo tee /var/run/secrets/kubeflow/pipelines/token