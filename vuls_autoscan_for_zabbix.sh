#!/bin/bash

ZABBIX_SERVER="localhost"

########################

VULS_HOME=`cd $(dirname $0) && pwd`
VULS_LOG="${VULS_HOME}/results"
RETRY=3

my_logger() {
    local priority="user.info"
    logger -i -p $priority -t `basename $0` "$1"
}

update() {
  local target=$1
  local option=$2
  local period=$3

  for i in `seq 1 3`
  do
    go-cve-dictionary ${option} -${period}
    if [ $? -eq 0 ];then
      my_logger "[INFO] Update success. [${target}]"
      break
    else
      if [ $i -lt $RETRY ];then
          my_logger "[INFO] Update retry. [${target}] (count=$i)"
          sleep 5
      else
          my_logger "[ERROR] Update retry over. [${target}] (count=$i)"
      fi      
    fi
  done
}

scan(){
  vuls scan -report-json -cve-dictionary-dbpath=${VULS_HOME}/cve.sqlite3
    if [ $? -eq 0 ];then
      my_logger "[INFO] Scan success."
    else
      my_logger "[ERROR] Scan fail."
      exit 1
    fi
}

send_zabbix(){
  files="${VULS_LOG}/current/*.json"
  for filepath in $files; do
    TARGET_NAME=`basename $filepath .json`
    if [ "${TARGET_NAME}" == "all" ]; then
      continue
    fi
      zabbix_sender -z ${ZABBIX_SERVER} -s ${TARGET_NAME} -k nvd_count -o `cat $filepath | jq '[.KnownCves[]?, .UnknownCves[]? | .CveDetail.CveID] | length'`
      zabbix_sender -z ${ZABBIX_SERVER} -s ${TARGET_NAME} -k nvd_max -o `cat $filepath | jq '[.KnownCves[]?, .UnknownCves[]? | .CveDetail.Nvd.Score]+[0] | max'`
   done
}

rotate(){
  firstDay=`date '+%Y-%m-01'`
  agoYear=`date -d "$firstDay 1 months ago" '+%Y'`
  agoMonth=`date -d "$firstDay 1 months ago" '+%m'`
  mkdir ${VULS_LOG}/$agoYear-$agoMonth > /dev/null 2>&1
  mv ${VULS_LOG}/$agoYear$agoMonth* ${VULS_LOG}/$agoYear-$agoMonth > /dev/null 2>&1
}


#======

cd ${VULS_HOME} 
  if [ $? -ne 0 ];then
    my_logger "[ERROR] path not found [${VULS_HOME}]"
    exit 1
  fi

## update ##
update NVD fetchnvd last2y 
update JVN fetchjvn last2y

## vuls scan ##
scan

## send zabbix ##
send_zabbix

## rotate ##
rotate

exit 0


