FROM httpd:2.4

RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install --no-install-recommends -y \
   python3 \
   python3-pip \
   python3-setuptools \
   procps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/share/doc \
 && rm -rf /usr/share/man

RUN pip3 install supervisor==4.2.2

COPY etc /etc/supervisor
COPY bin /usr/local/bin

RUN chmod +x /usr/local/bin/*.sh \
 && echo_supervisord_conf > /etc/supervisor/supervisord.conf \
 && echo "[include]" >> /etc/supervisor/supervisord.conf \
 && echo "files = conf.d/*.ini" >> /etc/supervisor/supervisord.conf

STOPSIGNAL SIGTERM

CMD ["supervisord", "--nodaemon", "-c", "/etc/supervisor/supervisord.conf"]