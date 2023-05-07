#!/bin/bash

sudo apt-get update

sudo apt-get -y install snapd && sudo snap install core && sudo snap refresh core && sudo snap install --classic certbot && sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates
sudo wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" > openresty.list
sudo cp openresty.list /etc/apt/sources.list.d/
echo "deb http://openresty.org/package/arm64/ubuntu $(lsb_release -sc) main"
sudo apt-get update
sudo apt-get -y install libnginx-mod-http-lua nginx openresty
sudo ufw allow http && sudo ufw allow https && sudo ufw allow 22 && sudo ufw allow 2053

echo -n "Please enter your domain:"
read configSSLDomain
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email wadqca@gmail.com -d $configSSLDomain
