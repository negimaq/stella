FROM ubuntu:jammy

WORKDIR /workdir

RUN apt update \
 && apt install -y tree curl xmlstarlet nkf imagemagick poppler-utils \
 && apt clean -y \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh

CMD ["/run.sh"]
