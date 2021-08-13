FROM httpd:2.4

RUN apt-get update \
 && apt-get install -y --no-install-recommends procps

ARG VERSION
ARG STOPSIGNAL=SIGWINCH

COPY start-${VERSION?}.sh /start.sh
RUN chmod +x /start.sh

STOPSIGNAL ${STOPSIGNAL}

CMD ["/start.sh"]