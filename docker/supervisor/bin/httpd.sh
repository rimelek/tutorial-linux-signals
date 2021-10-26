#!/bin/bash

echo "HELLO" > "/usr/local/apache2/htdocs/index.html"
exec httpd -D FOREGROUND
