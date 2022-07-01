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

# Use tensorflow-2.1.0 as a base image, allowing the user to
# speficy if they want GPU support, by setting IMAGE_TYPE to "gpu". 
FROM public.ecr.aws/c9e4w0g3/notebook-servers/jupyter-tensorflow:2.6.0-gpu-py38-cu112
USER root

# GPU Cuda repository public key updated 2022.04.27
RUN apt-key del 7fa2af80
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
RUN  dpkg -i cuda-keyring_1.0-1_all.deb
RUN sed -i '/developer\.download\.nvidia\.com\/compute\/cuda\/repos/d' /etc/apt/sources.list
RUN rm /etc/apt/sources.list.d/cuda*.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list
  
# Install basic dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates bash-completion tar less \ 
        python-setuptools build-essential python-dev \
        python3-pip python3-wheel && \
    rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FEEA9169307EA071
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B57C5C2836F4BEB

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
    #pip3 install --upgrade "jupyterlab>=2.0.0,<3.0.0"
    # Upgrade JupyterLab version to v3
    pip3 install --upgrade "jupyterlab>=3.1.6,<4.0.0"
RUN pip3 install --upgrade "kfp==1.8.2" 
   
# Pip packages 
RUN pip3 install --upgrade "matplotlib==3.5.1" 
RUN pip3 install --upgrade "seaborn==0.11.2" 

RUN pip3 install --upgrade "numpy==1.21.5"
RUN pip3 install --upgrade "pandas==1.3.5"
RUN pip3 install --upgrade "scikit-learn==1.0.2" 
RUN pip3 install --upgrade "pyarrow==7.0.0"
RUN pip3 install --upgrade "xgboost==1.5.2"
RUN pip3 install --upgrade "statsmodels==0.13.2"
 
RUN pip3 install --upgrade --user awscli==1.22.3
RUN pip3 install s3fs==2022.01.0

# kale 빌드로 생긴 Pipeline 수행 시, coroutine 에러 발생
# Bug in the Kale Jupyter Notebook Server Docker Image - Kale built pipeline execution fails · Issue #388 · kubeflow-kale/kale
# jupyter-client(5.3.4 -> 6.1.12), nbclient(0.5.5 -> 0.6.4), jinja2(2.11.3) 버전 변경 kale/backend/setup.py 

## Konlpy, Mecab을 돌리기 위한 Pip packages 추가 (from Eden)
RUN pip3 install --upgrade "collection==0.1.6"
RUN pip3 install --upgrade "JPype1==1.3.0"
RUN pip3 install --upgrade "konlpy==0.6.0"
RUN pip3 install --upgrade "tqdm==4.62.3" 

# Install JVM for Konlpy
RUN apt-get install -y \
    openjdk-8-jdk wget curl git python3-dev \
    language-pack-ko

RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Add Mecab-Ko
RUN curl -L https://raw.githubusercontent.com/konlpy/konlpy/master/scripts/mecab.sh | bash

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