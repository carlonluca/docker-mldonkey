FROM debian:wheezy

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y mldonkey-server && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/mldonkey && \
    rm /var/lib/mldonkey/*

USER mldonkey
ENV MLDONKEY_DIR /var/lib/mldonkey
VOLUME /var/lib/mldonkey
EXPOSE 4000 4080 19040 19044
ADD entrypoint.sh /
CMD /entrypoint.sh
