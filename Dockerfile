FROM node:22-bookworm AS builder-next

WORKDIR /root/
RUN \
    apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y ca-certificates curl gnupg git libatomic1 build-essential \
 && cd /root/ \
 && git clone https://github.com/carlonluca/mldonkey-next.git \
 && cd mldonkey-next/mldonkey-next-backend \
 && git checkout 6f259e796b2c45ac7630a1a3e0f4f84dc114656e \
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

FROM debian:buster AS builder

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends git build-essential \
        autoconf wget libz-dev libbz2-dev libmagic-dev libnatpmp-dev \
        libupnp-dev libgd-dev ca-certificates ocaml camlp4 ocaml-compiler-libs ocaml-nox \
        libminiupnpc-dev librsvg2-dev libgtk2.0-dev liblablgtk2-ocaml-dev liblablgtk2-gl-ocaml-dev liblablgtk2-gnome-ocaml-dev && \
    git clone https://github.com/carlonluca/mldonkey.git && \
    cd mldonkey && \
    git checkout 6fbc5014221484dd3559f4aa669453d916779589 && \
    mkdir -p patches && \
    ./configure --prefix=$PWD/out --enable-batch --enable-upnp-natpmp --disable-gnutella --disable-gnutella2 --enable-gui=newgui2 && \
    make -j1 && \
    make install

FROM debian:buster

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
        zlib1g libbz2-1.0 libmagic1 libgd3 netcat \
        libnatpmp1 libupnp13 libminiupnpc17 librsvg2-2 librsvg2-common \
        libgtk2.0-0 libgtk2.0-common \
        liblablgtk2-ocaml liblablgtk2-gl-ocaml liblablgtk2-gnome-ocaml && \
    apt-get install -y supervisor && \
    apt-get install -y procps && \
    apt-get -y --purge autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/mldonkey && \
    rm -rf /var/lib/mldonkey && \
    mkdir -p /var/lib/mldonkey && \
    mkdir /usr/lib/mldonkey/

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
