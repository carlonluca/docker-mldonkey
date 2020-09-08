FROM debian:latest

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y mldonkey-server && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/mldonkey && \
    rm /var/lib/mldonkey/*

RUN /usr/sbin/usermod -u 1001 mldonkey
RUN /usr/sbin/groupmod -g 1001 mldonkey

USER mldonkey
ENV MLDONKEY_DIR=/var/lib/mldonkey LC_ALL=C.UTF-8 LANG=C.UTF-8
VOLUME /var/lib/mldonkey
EXPOSE 4000 4080 19040 19044
ADD entrypoint.sh /
CMD /entrypoint.sh
