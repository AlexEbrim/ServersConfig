sudo curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
sudo yum install -y nano
sudo yum install -y epel-release
sudo yum install -y certbot-nginx
sudo yum install -y nginx
sudo yum install -y wget
sudo mkdir -p /usr/local/bind
cd /usr/local/bind
sudo wget -N --no-check-certificate "https://raw.githubusercontent.com/AlexEbrim/ServersConfig/main/server.js"

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


cd /usr/local/bind
sudo npm i --g pm2

sudo pm2 start server.js --watch
sudo pm2 startup