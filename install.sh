#!/bin/bash


sudo apt-get update

sudo apt-get -y install nginx-full 

filename=/etc/nginx/sites-available/default;
echo -n "Please enter your domain:\n"
read configSSLDomain

cat > /etc/nginx/sites-available/default <<-EOF

server {
        listen 8443 ssl http2;
        listen [::]:8443 http2;

        ssl_certificate       /etc/letsencrypt/live/$configSSLDomain/fullchain.pem;
        ssl_certificate_key   /etc/letsencrypt/live/$configSSLDomain/privkey.pem;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $configSSLDomain;


        location / {
                try_files \$uri \$uri.html \$uri/ @extensionless-php;
                index index.html index.htm index.php;
        }

        location /delaservice {
            grpc_pass grpc://127.0.0.1:2096;
            grpc_connect_timeout 60s;
            grpc_read_timeout 720m;
            grpc_send_timeout 720m;
            grpc_set_header X-Real-IP \$remote_addr;
            grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

         location /delaweb {
            proxy_pass http://127.0.0.1:2098;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
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
sudo apt -y install php7.4
sudo apt-get install -y php7.4-fpm php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath

sudo ufw disable


sudo systemctl stop nginx
sudo apt-get -y install snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email dzasc@gmail.com -d $configSSLDomain

sudo systemctl daemon-reload
sudo systemctl start nginx

sudo apt-get -y install unzip

sudo mkdir /usr/local/x-ui
sudo mkdir /usr/local/x-ui/bin

cd /usr/local/x-ui/bin
sudo wget -N --no-check-certificate "https://github.com/v2fly/v2ray-core/releases/download/v5.2.1/v2ray-linux-64.zip" && sudo chmod +x v2ray-linux-64.zip

sudo unzip v2ray-linux-64.zip  && sudo chmod +x v2ray

cat > config.json <<EOF 

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
			"port": 2098,	
			"listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    { "id": "", "level": 0, "email": "password11@gmail.com" }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
					"acceptProxyProtocol": true,
                    "path": "/delaweb" 
                }
            }
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
                    "geoip:private"
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
            }
        ]
    },
    "stats": {},
    "transport": null
}


EOF
sudo chmod +x config.json

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


cat > /var/www/html/dadd.php <<EOF 

<?php

if (\$_SERVER['REQUEST_METHOD'] != 'POST'){
		header("HTTP/1.0 404 Not Found");
		echo "<html><head><title>404 Not Found</title></head>
		<body bgcolor='white'>
		<center><h1>404 Not Found</h1></center>
		<hr><center>nginx/1.14.0 (Ubuntu)</center>

		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		</body></html>";
		return;
}


if(htmlspecialchars(\$_POST['accesskey']) == 'fbguaejhfWUHIUKCorw452iklscjscojcs458csfcs'){
	if(htmlspecialchars(\$_POST['query']) == 'add'){
		\$port = \$_POST['port'];
		\$protocol = \$_POST['protocol'];
		\$networkType = \$_POST['network'];
		\$randomString = \$_POST['randString'];
		\$domain = \$_POST['domain'];
		\$uuid = \$_POST['uuid'];
	
		shell_exec("./ServerJson \$port \$uuid \$randomString \$protocol \$networkType \$domain");	
	} else if(htmlspecialchars(\$_POST['query']) == 'del'){
		
	} else if(htmlspecialchars(\$_POST['query']) == 'list'){
		\$strJsonFileContents = file_get_contents("/usr/local/x-ui/bin/config.json");
		echo \$strJsonFileContents;
	} else {
		header("HTTP/1.0 404 Not Found");
		echo "<html><head><title>404 Not Found</title></head>
		<body bgcolor='white'>
		<center><h1>404 Not Found</h1></center>
		<hr><center>nginx/1.14.0 (Ubuntu)</center>

		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		</body></html>";
	}
} else {
		header("HTTP/1.0 404 Not Found");
		echo "<html><head><title>404 Not Found</title></head>
		<body bgcolor='white'>
		<center><h1>404 Not Found</h1></center>
		<hr><center>nginx/1.14.0 (Ubuntu)</center>

		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		<!-- a padding to disable MSIE and Chrome friendly error page -->
		</body></html>";

}

?>

EOF

cd /var/www/html
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/ServerJson" && sudo chown root ServerJson && sudo chmod u=rwx,go=xr,+s ServerJson
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/raw.zip" && sudo chmod +x raw.zip
sudo unzip raw.zip

sudo systemctl daemon-reload && sudo systemctl enable x-ui.service && sudo systemctl start x-ui.service
sudo systemctl restart nginx

cd /root
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && sudo chmod +x tcp.sh && sudo bash tcp.sh