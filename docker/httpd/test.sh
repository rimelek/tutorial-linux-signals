#!/bin/bash

set -eu

VERSION=$1
STOPSIGNAL=$2

root="$(cd "$(dirname "$0")" && pwd)/../.."

docker rm -f test 2>/dev/null
docker build -t localhost/httpd:$VERSION \
  --build-arg VERSION=$VERSION \
  --build-arg STOPSIGNAL=SIG$STOPSIGNAL \
  .
docker run \
    --name test \
    -v $root/tmp:/usr/local/apache2/htdocs/downloads \
    localhost/httpd:$VERSION

# curl http://172.17.0.2/downloads/large.iso -o large.iso