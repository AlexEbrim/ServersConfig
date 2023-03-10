#!/bin/bash


sudo apt-get update

sudo apt-get -y install nginx-full 

filename=/etc/nginx/sites-available/default;
echo -n "Please enter your domain:"
read configSSLDomain

cat > /etc/nginx/sites-available/default <<-EOF

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
sudo apt -y install php7.4
sudo apt-get install -y php7.4-fpm php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath

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
sudo wget https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat
sudo wget https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat

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
                "inboundSpeed": "8mbps",
                "outboundSpeed": "14mbps"
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
                    "regexp:.*\\.ir$",
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
		\$uuid = \$_POST['uuid'];
		\$user_id = \$_POST['user_id'];
		echo shell_exec("./addClient \$uuid \$user_id");
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
#sudo chown root ServerJson && sudo chmod u=rwx,go=xr,+s ServerJson
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/addClient" && sudo chmod +x addClient

sudo systemctl daemon-reload && sudo systemctl enable x-ui.service && sudo systemctl start x-ui.service
sudo apt-get -y purge apache2
sudo apt-get -y autoremove apache2
sudo systemctl restart nginx
#cd /root
#sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && sudo chmod +x tcp.sh && sudo bash tcp.sh