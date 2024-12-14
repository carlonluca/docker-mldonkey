FROM node:23.3.0-bookworm AS builder-next

WORKDIR /root/
RUN \
    apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y ca-certificates curl gnupg git libatomic1 build-essential \
 && cd /root/ \
 && git clone https://github.com/carlonluca/mldonkey-next.git \
 && cd mldonkey-next/mldonkey-next-backend \
 && git checkout 188405f \
 && npm config set fetch-timeout 600000 \
 && npm i --maxsockets 1 \
 && npm run build \
 && npm i webpack-cli webpack \
 && npx webpack \
 && node --experimental-sea-config sea-config.json \
 && cp $(command -v node) mldonkey-next \
 && npx postject mldonkey-next NODE_SEA_BLOB sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 \
 && cd .. \
 && cd mldonkey-next-frontend \
 && npm install -g @angular/cli \
 && npm i --maxsockets 1 \
 && ng build

FROM carlonluca/mldonkey-dev:noble AS builder

RUN \
    export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y update \
 && apt-get -y upgrade \
 && apt-get install libc6-dev \
 && git clone https://github.com/carlonluca/mldonkey.git \
 && cd mldonkey \
 && git checkout b1cc3e44 \
 && mkdir -p patches \
 && ./configure --prefix=$PWD/out --enable-batch --enable-upnp-natpmp --enable-gnutella --enable-gnutella2 --disable-gui \
 && make -j1 \
 && make install

FROM ubuntu:noble

# Remove the ubuntu user.
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

RUN \
    export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y update \
 && apt-get -y upgrade \
 && apt-get install --no-install-recommends -y \
        zlib1g libbz2-1.0 libmagic1t64 libgd3 netcat-openbsd \
        libnatpmp1t64 libupnp17t64 libminiupnpc17 librsvg2-2 librsvg2-common \
 && apt-get install -y supervisor \
 && apt-get install -y procps \
 && apt-get -y --purge autoremove \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/log/mldonkey \
 && rm -rf /var/lib/mldonkey \
 && mkdir -p /var/lib/mldonkey \
 && mkdir /usr/lib/mldonkey/

RUN useradd -ms /bin/bash mldonkey \
 && mkdir -p /var/log/supervisor \
 && mkdir -p /usr/bin/dist/mldonkey-next

COPY --from=builder-next /root/mldonkey-next/mldonkey-next-frontend/dist /usr/bin/dist
COPY --from=builder-next /root/mldonkey-next/mldonkey-next-backend/mldonkey-next /usr/bin/mldonkey-next
COPY --from=builder /mldonkey/out/bin/* /usr/bin/
COPY --from=builder /mldonkey/distrib/mldonkey_command /usr/lib/mldonkey/

ENV MLDONKEY_DIR=/var/lib/mldonkey LC_ALL=C.UTF-8 LANG=C.UTF-8
VOLUME /var/lib/mldonkey

# 4001 - TCP socket
# 4002 - Websocket
EXPOSE 4000 4001 4002 4080 4081 19040 19044

ADD entrypoint.sh /
ADD init.sh /
ADD run_supervisord.sh /
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/run_supervisord.sh"]
