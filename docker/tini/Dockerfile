FROM python:3.8

RUN apt-get update \
 && apt-get install -y --no-install-recommends tini

ENTRYPOINT [ "tini", "--" ]
CMD ["python3", "-m", "http.server", "8080"]
