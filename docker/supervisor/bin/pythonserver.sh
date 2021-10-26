#!/bin/bash

mkdir -p /var/www

echo "Hello Python server" > /var/www/index.html
python3 -u -m http.server --directory /var/www 8080