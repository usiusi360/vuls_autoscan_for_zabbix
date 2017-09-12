#!/bin/bash

ZABBIX_SERVER="localhost"
RETRY=3
PAST_YEAR=2
#PROXY="-http-proxy=http://proxy.hogehoge.co.jp:10080"

########################

VULS_HOME=`cd $(dirname $0) && pwd`
VULS_LOG="${VULS_HOME}/results"

my_logger() {
    local priority="user.info"
    logger -i -p $priority -t `basename $0` "$1"
}

update() {
  local target=$1

  local last_year=`date +%Y`
  local first_year=`expr ${last_year} - ${PAST_YEAR} + 1`
  local years=""
  for i in `seq ${first_year} 1 ${last_year}`
  do
    years="${years} $i"
  done

  for i in `seq 1 ${RETRY}`
  do
    go-cve-dictionary fetch${target} ${PROXY} -years $years
    if [ $? -eq 0 ];then
      my_logger "[INFO] Update success. [${target}]"
      break
    else
      if [ $i -lt $RETRY ];then
          my_logger "[INFO] Update retry. [${target}] (count=$i)"
          sleep 10
      else
          my_logger "[ERROR] Update retry over. [${target}] (count=$i)"
      fi      
    fi
  done
}

update_oval() {
  local target=$1
  local option="$2"

  for i in `seq 1 ${RETRY}`
  do
    goval-dictionary fetch-${target} ${PROXY} ${option}
    if [ $? -eq 0 ];then
      my_logger "[INFO] Update-OVAL success. [${target}]"
      break
    else
      if [ $i -lt $RETRY ];then
          my_logger "[INFO] Update-OVAL retry. [${target}] (count=$i)"
          sleep 5
      else
          my_logger "[ERROR] Update-OVAL retry over. [${target}] (count=$i)"
      fi     
    fi
  done
}

scan(){
  vuls scan -deep
    if [ $? -eq 0 ];then
      my_logger "[INFO] Scan success."
    else
      my_logger "[ERROR] Scan fail."
      exit 1
    fi
}


report(){
  vuls report -format-json
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
      zabbix_sender -z ${ZABBIX_SERVER} -s ${TARGET_NAME} -k nvd_count -o `cat $filepath | jq '.ScannedCves? | length'`
      zabbix_sender -z ${ZABBIX_SERVER} -s ${TARGET_NAME} -k nvd_max -o `cat $filepath | jq '[.ScannedCves[] | .CveContents.nvd.Cvss2Score]+[0] | max'`
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
update nvd
update jvn

## update oval ##
#update_oval redhat "5 6 7"
#update_oval debian "7 8 9 10"
#update_oval ubuntu "12 14 16"
#update_oval oracle

## vuls scan ##
scan

## vuls report ##
report

## send zabbix ##
send_zabbix

## rotate ##
#rotate

exit 0


