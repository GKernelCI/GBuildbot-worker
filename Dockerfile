FROM        buildbot/buildbot-worker:v2.8.2
MAINTAINER  alicef@gentoo.org

USER root

# This will make apt-get install without question
ARG DEBIAN_FRONTEND=noninteractive

# Install required packages and updates
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get -y install -q \
    python3-pip \
    libelf-dev \
    bc \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Install python required packages
RUN pip3 install --upgrade pip
RUN pip3 install virtualenv
RUN pip3 install lavacli
RUN pip3 install beautifulsoup4
RUN pip3 install lxml

# Create fileserver folder for passing files to lava
RUN mkdir -p /var/www/fileserver
RUN chown -R buildbot /var/www/fileserver

USER buildbot
WORKDIR /buildbot

# Getting lava settings from docker-compose.yml
ARG LAVA_TOKEN
ARG LAVA_USER
ARG LAVA_SERVER

RUN mkdir -p ~/.config/
RUN printf 'buildbot:\n  uri: http://$LAVA_USER:$LAVA_TOKEN@$LAVA_SERVER/RPC2' > ~/.config/lavacli.yaml
RUN lavacli identities add --uri http://$LAVA_USER:$LAVA_TOKEN@$LAVA_SERVER/RPC2 buildbot
