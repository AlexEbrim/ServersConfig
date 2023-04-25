sudo curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
sudo yum install -y nano
sudo yum install -y epel-release
sudo yum install -y certbot-nginx
sudo yum install -y nginx
sudo mkdir -p /usr/local/bind
cd /usr/local/bind
sudo npm install http
sudo npm install https
sudo npm install express
sudo npm install --save-dev http-proxy-middleware

sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-service=https
sudo firewall-cmd --runtime-to-permanent

echo -n "Please enter your domain:"
read configSSLDomain

sudo certbot --nginx -d $configSSLDomain
sudo systemctl enable nginx && sudo systemctl start nginx
cat > /etc/systemd/system/bind.service <<EOF 

[Unit]
Description=bind Service
After=network.target
Wants=network.target

[Service]
Type=simple
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
WorkingDirectory=/usr/local/server/
ExecStart=/usr/bin/node run -config /usr/local/server/bind.js
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl daemon-reload && sudo systemctl restart bind.service && sudo systemctl start bind.service