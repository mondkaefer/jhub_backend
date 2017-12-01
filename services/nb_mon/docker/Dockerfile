FROM debian:jessie
COPY src /root/src
ENV http_proxy http://squid.auckland.ac.nz:3128
ENV https_proxy http://squid.auckland.ac.nz:3128
RUN apt-get update && \
    apt-get install -y python3 && \
    apt-get install -y python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install -r /root/src/requirements.txt && \
    echo "Pacific/Auckland" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /root/src
CMD ["./nbs_mon.sh"]
