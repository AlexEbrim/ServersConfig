#!/bin/bash


sudo apt-get update
sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo npm install -g npm@latest
sudo apt-get -y install nginx-full 

sudo apt -y install ufw && sudo ufw allow 56777 && sudo ufw allow 443 && sudo ufw allow 8443 && sudo ufw allow 8080 && sudo ufw allow 80 && sudo ufw enable

filename=/etc/nginx/sites-available/default;
echo -n "Please enter your domain:"
read configSSLDomain

cat > /etc/nginx/sites-available/default <<-EOF

server {
  listen 8443 ssl http2;
  listen [::]:8443 http2;
  
  ssl_certificate       /etc/letsencrypt/live/$configSSLDomain/fullchain.pem;
  ssl_certificate_key   /etc/letsencrypt/live/$configSSLDomain/privkey.pem;
  ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers           HIGH:!aNULL:!MD5;
  server_name           $configSSLDomain;
		
		location /delawebs {
			proxy_pass http://127.0.0.1:443;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;

            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		}

  location / {
    return 204;
  }
}

server {
        listen 80;
        listen [::]:80;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $configSSLDomain;


        location / {
                try_files \$uri \$uri.html \$uri/ @extensionless-php;
                index index.html index.htm index.php;
        }
		
        location ~ \.php\$ {
                try_files \$uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_pass unix:/var/run/php/php-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
        }

        location @extensionless-php {
                rewrite ^(.*)\$ \$1.php last;
        }

}

EOF

sudo apt -y install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt -y install php7.2
sudo apt-get install -y php7.2-fpm php7.2-cli php7.2-json php7.2-common php7.2-mysql php7.2-zip php7.2-gd php7.2-mbstring php7.2-curl php7.2-xml php7.2-bcmath autoconf zlib1g-dev php7.2-dev php-pear

sudo ufw disable


sudo systemctl stop nginx
sudo apt-get -y install snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email rxgbhsxg@gmail.com -d $configSSLDomain

sudo systemctl daemon-reload
sudo systemctl start nginx

sudo apt-get -y install unzip

sudo mkdir /usr/local/x-ui
sudo mkdir /usr/local/x-ui/bin

cd /usr/local/x-ui/bin
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/v2ray" && sudo chmod +x v2ray
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/api" && sudo chmod +x api
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/addClient.js"
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/server.proto"
sudo wget -N --no-check-certificate "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
sudo wget -N --no-check-certificate "https://github.com/v2fly/geoip/releases/latest/download/geoip-only-cn-private.dat"
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/geosite.dat"
sudo wget -N --no-check-certificate "https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat"
sudo wget -N --no-check-certificate "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"

sudo npm install @grpc/grpc-js
sudo npm install @grpc/proto-loader

cat > /usr/local/x-ui/bin/config.json <<EOF 

{
    "api": {
        "services": [
            "HandlerService",
            "LoggerService",
            "StatsService"
        ],
        "tag": "api"
    },
    "dns": null,
    "fakeDns": null,
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": 8080,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            },
            "sniffing": null,
            "streamSettings": null,
            "tag": "api"
        },
		{
            "listen": null,
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    
                ],
                "decryption": "none",
                "fallbacks": []
            },
            "sniffing": {
                "destOverride": [
                    "http",
                    "tls"
                ],
                "enabled": true
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/letsencrypt/live/$configSSLDomain/fullchain.pem",
                            "keyFile": "/etc/letsencrypt/live/$configSSLDomain/privkey.pem"
                        }
                    ],
                    "serverName": "$configSSLDomain"
                },
                "wsSettings": {
                    "headers": {},
                    "path": "/delawebs"
                }
            },
            "tag": "add_user"
        }
    ],
    "log": null,
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4"
            },
            "tag": "IPv4-out"
        },
        {
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            },
            "tag": "IPv6-out"
        },
        {
            "protocol": "blackhole",
            "tag": "blackhole-out"
        }
    ],
    "policy": {
	"levels": {
            "0": {
                "inboundSpeed": "18mbps",
                "outboundSpeed": "18mbps"
            }
        },
        "system": {
            "statsInboundDownlink": false,
            "statsInboundUplink": false
        }
    },
    "reverse": null,
    "routing": {
        "rules": [
            {
                "inboundTag": [
                    "api"
                ],
                "outboundTag": "api",
                "type": "field"
            },
            {
                "ip": [
                    "geoip:private",
                    "geoip:ir"
                ],
                "outboundTag": "blocked",
                "type": "field"
            },
            {
                "outboundTag": "blocked",
                "protocol": [
                    "bittorrent"
                ],
                "type": "field"
            },
            {
                "domain": [
                    "regexp:.*\\\.ir$",
                    "ext:iran.dat:ir",
                    "ext:iran.dat:other",
                    "geosite:category-ir-gov",
                    "geosite:category-ir-news",
                    "geosite:category-ir-bank",
                    "geosite:category-ir-tech",
                    "geosite:category-ir-travel",
                    "geosite:category-ir-shopping",
                    "geosite:category-ir-insurance",
                    "geosite:category-ir-scholar",
                    "snapp",
                    "digikala",
                    "tapsi",
                    "blogfa",
                    "bank",
                    "sb24.com",
                    "sheypoor.com",
                    "tebyan.net",
                    "beytoote.com",
                    "telewebion.com",
                    "Film2movie.ws",
                    "Setare.com",
                    "Filimo.com",
                    "Torob.com",
                    "Tgju.org",
                    "Sarzamindownload.com",
                    "downloadha.com",
                    "P30download.com",
                    "Sanjesh.org"
                ],
                "outboundTag": "blocked",
                "type": "field"
            }
        ]
    },
    "stats": {},
    "transport": null
}


EOF
sudo chmod 777 config.json

cat > /etc/systemd/system/x-ui.service <<EOF 

[Unit]
Description=x-ui Service
After=network.target
Wants=network.target

[Service]
Type=simple
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
WorkingDirectory=/usr/local/x-ui/
ExecStart=/usr/local/x-ui/bin/v2ray run -config /usr/local/x-ui/bin/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/systemd/system/api.service <<EOF 

[Unit]
Description=addClient.js
After=network.target

[Service]
Environment=NODE_PORT=5000
Type=simple
User=root
ExecStart=/usr/bin/node /usr/local/x-ui/bin/addClient.js
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF


sudo mkdir /var/www/html
cd /var/www/html/
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/api.zip"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo unzip api.zip && sudo sudo rm -rf api.zip
sudo composer install

sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/grpc.zip"
sudo unzip grpc.zip && sudo rm -rf grpc.zip
sudo cp grpc.so /usr/lib/php/20170718/grpc.so;
#sudo chown root ServerJson && sudo chmod u=rwx,go=xr,+s ServerJson

sudo service php7.2-fpm restart

cd /root
sudo systemctl daemon-reload && sudo systemctl enable x-ui.service && sudo systemctl start x-ui.service && sudo systemctl enable api.service && sudo systemctl start api.service
sudo apt-get -y purge apache2
sudo apt-get -y autoremove apache2
sudo systemctl restart nginx
#cd /root
#sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && sudo chmod +x tcp.sh && sudo bash tcp.sh