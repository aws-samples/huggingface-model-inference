# Example neuron-rtd dockerfile.

FROM amazonlinux:2

LABEL maintainer="Fabio Nonato (fnp@)"

RUN echo $'[neuron] \n\
name=Neuron YUM Repository \n\
baseurl=https://yum.repos.neuron.amazonaws.com \n\
enabled=1' > /etc/yum.repos.d/neuron.repo

RUN rpm --import https://yum.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB

RUN yum update -y && yum install -y \
    aws-neuron-runtime-base \
    aws-neuron-runtime \
    aws-neuron-tools  

RUN yum install -y \
    tar \
    gzip \
    ca-certificates \
    procps \
    net-tools \
    which \
    vim \
    wget \
    libgomp \
    jq \
    python3 \
    python3-devel \
    gcc-c++ \
    git

RUN pip3 install --upgrade --force-reinstall --no-cache-dir \ 
    neuron-cc \
    torch-neuron \
    transformers \
    captum \
    --extra-index-url=https://pip.repos.neuron.amazonaws.com  

# Installing opnejdk11
RUN amazon-linux-extras install java-openjdk11 

RUN pip3 install --no-cache-dir \
    torchserve==0.3.0 torch-model-archiver==0.3.0 protobuf

ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE

# Set up the model in the image
COPY ./model_store /opt/model_store
COPY ./config.properties /opt/config.properties 
COPY ./dockerd-entrypoint.sh /opt/bin/dockerd-entrypoint.sh
RUN chmod +x /opt/bin/dockerd-entrypoint.sh
ENV PATH="/opt/bin/:/opt/aws/neuron/bin:${PATH}"

WORKDIR /opt

EXPOSE 8443

ENTRYPOINT ["/opt/bin/dockerd-entrypoint.sh"]

CMD ["serve"]
