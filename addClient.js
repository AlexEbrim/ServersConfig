var PROTO_PATH = '/usr/local/x-ui/bin/server.proto';
const fsPromises = require('fs').promises;
var grpc = require('@grpc/grpc-js');
var protoLoader = require('@grpc/proto-loader');
var packageDefinition = protoLoader.loadSync(
    PROTO_PATH,
    {keepCase: true,
     longs: String,
     enums: String,
     defaults: true,
     oneofs: true
    });

   
var add_proto = grpc.loadPackageDefinition(packageDefinition).addclient;
const { exec } = require('node:child_process')

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function sendRequest(call, callback) {
  const fsPromises = require('fs').promises;
fsPromises.readFile('/usr/local/x-ui/bin/config.json', 'utf8') 
        .then(data => { 
                let mainJson = JSON.parse(data);

                let findUser = false;
                let inboundEmpty = mainJson["inbounds"].length == 0;
                if (!inboundEmpty) {
                  let clients = mainJson["inbounds"][1]["settings"]["clients"];
                  for (let j = 0; j < clients.length; j++) {
                      let id = clients[j]["id"];
                      if (id == call.request.uuid) {
                           findUser = true;
                           break;
                      }
                  }
                }
                if(findUser){
                  callback(null, {message: 'user_exists'});
                  return;
                }

                mainJson["inbounds"][1]["settings"]["clients"].push({id: call.request.uuid, email: call.request.email + "@delavpn.com", alterId: 64, level: 0});
                fsPromises.writeFile('/usr/local/x-ui/bin/config.json', JSON.stringify(mainJson))
                        .then(  async () => { 
                          exec('/usr/local/x-ui/bin/api api adi --server=127.0.0.1:8080 --uuid=' + call.request.uuid + " --id=" + call.request.email, (err, output) => {
                            if (err || output == "Error") {
                              callback(null, {message: ''});
                                return;
                            } else {
                              callback(null, {message: "Added!"});
                            }
                        })
                        await sleep(500);
                        })
                        .catch(err => { 
                          callback(null, {message: ''});
                        });
            })
        .catch(err => {
          callback(null, {message: ''});
          });
        
}


function main() {
  var server = new grpc.Server();
  server.addService(add_proto.AddClient.service, {sendRequest: sendRequest});
  server.bindAsync('0.0.0.0:5000', grpc.ServerCredentials.createInsecure(), () => {
    server.start();
  });
}

main();
