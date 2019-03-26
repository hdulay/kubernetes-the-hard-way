FROM google/cloud-sdk:latest
ADD . /work
WORKDIR /work
RUN apt-get update
RUN apt-get install systemd
RUN apt-get install vim -y
RUN apt-get install pssh -y
RUN  apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/*

RUN wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

RUN chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
RUN mv cfssl_linux-amd64 /usr/local/bin/cfssl
RUN mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv kubectl /usr/local/bin/

