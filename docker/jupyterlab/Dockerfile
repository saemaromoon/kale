#  Copyright 2022 The saemaromoon Authors
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License. 
FROM jupyter/tensorflow-notebook:python-3.9.12
USER root

# CUDA Installation guide
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installation-guide
RUN apt-get update && apt-get install -y curl gnupg
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list 

RUN apt-get update
RUN apt-get install -y nvidia-docker2

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates bash-completion tar less \ 
    python-setuptools build-essential python-dev \
    python3-pip python3-wheel && \
    rm -rf /var/lib/apt/lists/* 

RUN apt-get update
RUN apt-get -y install build-essential libpq-dev libssl-dev openssl libffi-dev zlib1g-dev

RUN apt-get -y install python3-pip
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update 
RUN python3 -m pip install pip --upgrade

ENV SHELL /bin/bash
COPY bashrc /etc/bash.bashrc
RUN echo "set background=dark" >> /etc/vim/vimrc.local

# Install latest KFP SDK
RUN pip3 freeze
RUN pip3 install --upgrade pip && \
    # XXX: Install enum34==1.1.8 because other versions lead to errors during
    #  KFP installation
    pip3 install --upgrade "enum34==1.1.8" && \
    pip3 install --upgrade "jupyterlab>=2.0.0,<3.0.0"
# Upgrade JupyterLab version to v3
# pip3 install --upgrade "jupyterlab>=3.1.6,<4.0.0"
RUN pip3 install --upgrade "kfp==1.8.2" 

# Pip packages 
RUN pip3 install --upgrade "matplotlib==3.5.1" 
RUN pip3 install --upgrade "seaborn==0.11.2" 

RUN pip3 install --upgrade "numpy==1.21.5"
RUN pip3 install --upgrade "pandas==1.5.2"
RUN pip3 install --upgrade "scikit-learn==1.0.2" 
RUN pip3 install --upgrade "pyarrow==8.0.0"
RUN pip3 install --upgrade "xgboost==1.5.2"
RUN pip3 install --upgrade "statsmodels==0.13.2"
RUN pip3 install --upgrade "ray[air]==2.2.0"
RUN pip3 install --upgrade "tensorflow==2.11.0"
RUN pip3 install --upgrade "protobuf==3.19.6"

RUN apt-get update
RUN pip3 install --upgrade "botocore==1.27.24"
RUN pip3 install --upgrade "boto3==1.24.24"
RUN pip3 install --upgrade "s3fs==2022.5.0"
RUN pip3 install --upgrade "s3transfer==0.6.0"
RUN pip3 install --upgrade "awscli==1.25.24" 

# kale 빌드로 생긴 Pipeline 수행 시, coroutine 에러 발생
# Bug in the Kale Jupyter Notebook Server Docker Image - Kale built pipeline execution fails · Issue #388 · kubeflow-kale/kale
# jupyter-client(5.3.4 -> 6.1.12), nbclient(0.5.5 -> 0.6.4), jinja2(2.11.3) 버전 변경 kale/backend/setup.py 

## Konlpy, Mecab을 돌리기 위한 Pip packages 추가 (from Eden)
RUN pip3 install --upgrade "collection==0.1.6"
RUN pip3 install --upgrade "JPype1==1.3.0"
RUN pip3 install --upgrade "konlpy==0.6.0"
RUN pip3 install --upgrade "tqdm==4.62.3" 

## Biglab request 220118
RUN pip3 install --upgrade pymysql==1.0.2 sqlalchemy==1.4.46 cryptocode==0.1 pyproj==3.4.1 
RUN pip3 install --upgrade geopandas==0.12.2 gspread==5.7.2 oauth2client==4.1.3 ipynb==0.5.1
RUN pip3 install --upgrade keras-bert==0.89.0 keras-radam==0.15.0 networkx==2.8.8 
RUN pip3 install --upgrade python-dotenv==0.21.0 openpyxl==3.0.10  

## Korean font setting
RUN apt-get install fonts-nanum*
RUN matloc=$(pip3 show matplotlib | grep Location | sed "s/ //g"| sed -r 's/[:]+/=/g' | awk -F= '{a[$1]=$2} END {print(a["Location"])}' 2>&1) \
    && sed -i 's/#font.family:  sans-serif/font.family: NanumGothic/g' $matloc/matplotlib/mpl-data/matplotlibrc

# Install JVM for Konlpy
RUN apt-get install -y \
    openjdk-8-jdk wget curl git python3-dev \
    language-pack-ko

RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Add Mecab-Ko
RUN bash <(curl -s https://raw.githubusercontent.com/konlpy/konlpy/master/scripts/mecab.sh)

# Install Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

ARG DISABLE_CACHE

# Install Kale from KALE_BRANCH (defaults to "sean")
ARG KALE_BRANCH="sean"
WORKDIR /
RUN git clone -b ${KALE_BRANCH} https://github.com/saemaromoon/kale

WORKDIR /kale/backend
RUN pip3 install --upgrade .

WORKDIR /kale/labextension
RUN jlpm install && \
    jlpm run build && \
    jupyter labextension install .

RUN jupyter lab build --dev-build=False

RUN echo "jovyan ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan
WORKDIR /home/jovyan
USER jovyan

COPY config.sh /etc/config.sh

CMD ["sh", "-c", \
    "jupyter lab --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser \
    --allow-root --port=8888 --LabApp.token='' --LabApp.password='' \
    --LabApp.allow_origin='*' --LabApp.base_url=${NB_PREFIX}"]