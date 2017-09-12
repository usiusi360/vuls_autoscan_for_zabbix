#!/bin/bash

ZABBIX_SERVER="localhost"
ZABBIX_USER="Admin"
ZABBIX_PASS="hogehoge"

###########################

VULS_HOME=`cd $(dirname $0) && pwd`
url="http://${ZABBIX_SERVER}/zabbix/api_jsonrpc.php"
curl_comm='curl -s -X POST -H Content-Type:application/json-rpc --data @_tmp_json'

cd ${VULS_HOME}
if [ ! -e config.toml.master ]; then
  echo "Not found [config.toml.master]"
  exit 1
fi

#===== authentication
cat << EOS > _tmp_json
{
    "jsonrpc": "2.0",
    "method": "user.login",
    "params": {
        "user": "${ZABBIX_USER}",
        "password": "${ZABBIX_PASS}"
    },
    "id": 1
}
EOS

session_id=`$curl_comm $url | jq -r '.result'`

if [ "$session_id" == "" ];then
  echo "Authentication fail"
  exit 1
fi

#===== getHostdata
cat << EOS > _tmp_json
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": [ "host" , "available" , "status" ],
        "selectInterfaces" : [ "ip" , "type" ],
        "sortfield" : "host",
        "filter" : {
                    "available" : [ "1" ],
                    "status" : [ "0" ]
                   }
    },
    "auth": "$session_id",
    "id": 2
}
EOS

$curl_comm $url | jq -r '.result[] | "\(.interfaces[] | select(.type=="1") | .ip) \(.host)"' | uniq -f 1 > _tmp_serverlist

if [ -e ignore.list ]; then
  while read line; do
    sed -i "/$line/d" _tmp_serverlist
  done < ignore.list
fi

#===== createConfig #####
echo "" > _tmp_config
echo "[servers]" > _tmp_config
while read line; do
    serverIP=`echo "$line" | cut -d " " -f1`
    serverName=`echo "$line" | cut -d " " -f2`
    echo "[servers.$serverName]" >> _tmp_config
    echo "host = \"$serverIP\"" >> _tmp_config
    echo "" >> _tmp_config
done < _tmp_serverlist

cat config.toml.master _tmp_config > config.toml


