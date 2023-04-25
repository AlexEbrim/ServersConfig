const express = require('express');
const https = require('https');
const fs = require('fs');
const { createProxyMiddleware } = require('http-proxy-middleware');


var options = {
  cert: fs.readFileSync("/etc/letsencrypt/live/book-ir.ddns.net/fullchain.pem", 'utf8'),
  key: fs.readFileSync("/etc/letsencrypt/live/book-ir.ddns.net/privkey.pem", 'utf8')
};

const wsProxy = createProxyMiddleware({
  target: '/',
  changeOrigin: true,
  ws: true,
  router: (req) => {
    req.headers['X-Real-IP'] = "1.1.1.1"
    req.headers['X-Forwarded-For'] = "1.1.1.1"
    var port = `${req.headers["host"].split(":")[1]}`;
    var needHttps = "http://";
    if(port == 443 || port == 8443 || port == 2053 || port == 2096 || port == 2083 || port == 2087){
      needHttps = "https://"
    }
    console.log(`${needHttps}${req.headers["host"].split(":")[0]}:${port}`)
    return `${needHttps}${req.headers["host"].split(":")[0]}:${port}`;
  },
});

const app = express();

var server = https.createServer(options, app).listen(443, () => {});

app.use('/', express.static(__dirname)); 
app.use(wsProxy);

server.on('upgrade', wsProxy.upgrade);
