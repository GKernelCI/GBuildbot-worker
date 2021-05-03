FROM        buildbot/buildbot-worker:v3.1.1
MAINTAINER  alicef@gentoo.org

USER root

# This will make apt-get install without question
ARG DEBIAN_FRONTEND=noninteractive

# Install required packages and updates
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get -y install -q \
    clang clang-11 llvm llvm-11 lld lld-11 \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    gcc-sparc64-linux-gnu \
    gcc-powerpc-linux-gnu \
    gcc-powerpc64-linux-gnu \
    python3 \
    build-essential \
    kmod \
    gnupg \
    libtool \
    python3-pip \
    libelf-dev \
    bc \
    docker.io \
    bison \
    flex \
    vim \
    autoconf \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11 100

# Install python required packages
RUN pip3 install --upgrade pip
RUN pip3 install virtualenv
RUN pip3 install lavacli
RUN pip3 install beautifulsoup4
RUN pip3 install lxml
RUN pip3 install jsonschema
RUN pip3 install pyyaml
RUN pip3 install python-dateutil
# Install newer jq fork version compatible with latest pip
RUN pip3 install jq@git+https://github.com/spbnick/jq.py.git@1.1.2.post1
RUN pip3 install --use-deprecated=legacy-resolver git+https://github.com/kernelci/kcidb.git@v8

# Create fileserver folder for passing files to lava
RUN mkdir -p /var/www/fileserver
RUN chown -R buildbot /var/www/fileserver

ARG DOCKER_GID
RUN groupmod -g $DOCKER_GID docker
RUN usermod --append -G docker buildbot

USER root
WORKDIR /buildbot

# Add kcidb configuration (if you are not sending to kernelci just comment out this)
COPY .kernelci-ci-gkernelci.json /home/buildbot/.kernelci-ci-gkernelci.json
ARG GOOGLE_APPLICATION_CREDENTIALS=~/.kernelci-ci-gkernelci.json

COPY update-llvm.sh /
RUN apt-get -y remove llvm lld && sh /update-llvm.sh

# Getting lava settings from docker-compose.yml
ARG LAVA_TOKEN
ARG LAVA_USER
ARG LAVA_SERVER

USER buildbot
RUN mkdir -p ~/.config/
RUN printf 'buildbot:\n  uri: http://$LAVA_USER:$LAVA_TOKEN@$LAVA_SERVER/RPC2' > ~/.config/lavacli.yaml
RUN lavacli identities add --uri http://$LAVA_USER:$LAVA_TOKEN@$LAVA_SERVER/RPC2 buildbot

# See https://www.gentoo.org/downloads/signatures/
RUN gpg --keyserver hkps://keys.gentoo.org --receive-keys 13EBBDBEDE7A12775DFDB1BABB572E0E2D182910
