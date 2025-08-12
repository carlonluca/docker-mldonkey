FROM node:23.5.0-bookworm AS builder-next

WORKDIR /root/
RUN \
    apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y ca-certificates curl gnupg git libatomic1 build-essential \
 && cd /root/ \
 && git config --global user.name "Luca Carlon" \
 && git config --global user.email "carlon.luca@gmail.com" \
 && git clone https://github.com/carlonluca/mldonkey-next.git \
 && cd mldonkey-next/mldonkey-next-backend \
 && git checkout 056afe2 \
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
 && npm run build

FROM ubuntu:plucky AS builder

RUN \
    DEBIAN_FRONTEND=noninteractive \
 && apt-get -y update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends ca-certificates libcurl4-gnutls-dev zlib1g-dev git-lfs m4 \
    opam build-essential autoconf wget libz-dev libbz2-dev libmagic-dev libnatpmp-dev \
    libupnp-dev libgd-dev ca-certificates libminiupnpc-dev librsvg2-dev \
    libc6-dev python-is-python3 libcrypto++-dev \
 && git clone https://github.com/carlonluca/mldonkey.git \
 && cd mldonkey \
 && git checkout c907ebd6 \
 && python autoconf.py \
 && opam init --disable-sandboxing --bare --yes --jobs=$(nproc) \
 && eval $(opam env) \
 && opam switch create --yes --jobs=$(nproc) 5.3.0 \
 && eval $(opam env --switch=5.3.0) \
 && opam install . --deps-only --yes --jobs=$(nproc) \
 && opam exec -- dune build --profile release

FROM ubuntu:plucky

# Remove the ubuntu user.
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

RUN \
    export DEBIAN_FRONTEND=noninteractive \
 && apt-get -y update \
 && apt-get -y upgrade \
 && apt-get install --no-install-recommends -y \
        zlib1g libbz2-1.0 libmagic1t64 libgd3 netcat-openbsd \
        libnatpmp1t64 libupnp17t64 miniupnpc librsvg2-2 librsvg2-common \
        libatomic1 libcurl4-gnutls-dev libcrypto++-dev \
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
COPY --from=builder /mldonkey/_build/default/src/mlnet.exe /usr/bin/mlnet
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
