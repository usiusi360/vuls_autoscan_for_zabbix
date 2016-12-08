# vuls_autoscan_for_zabbix #

vuls_autoscan_for_zabbix can work together the contents [Vuls](https://github.com/future-architect/vuls) detects to zabbix.

## Abstract

vuls_autoscan_for_zabbix is performed as follows.

> 1. Vulnerability information (NVD · JVN) update

>  ↓

> 2. Vuls scan

>  ↓

> 3. Result cooperation to Zabbix

>  ↓

> 4. Rotation of Vuls JSON file


## Installation

### Place the shell script
Put "vuls_scan_to_zabbix.sh" to "Home Folder" on Vuls.
And set the execution authority.


```
$ cd /opt/vuls
$ wget https://github.com/usiusi360/vuls_autoscan_for_zabbix/vuls_autoscan_for_zabbix.sh
$ chmod 700 vuls_autoscan_for_zabbix.sh
```

Changed to match the address of the Zabbix server in the script to the environment.


```
$ vi vuls_autoscan_for_zabbix.sh
---------
#!/bin/bash
ZABBIX_SERVER="localhost" 　←★ Change
---------
```

If you jq and zabbix-sender is not installed, you must install.


```
$ yum install jq zabbix-sender
```

## Setting Zabbix

Download the "Template_Vuls.xml" and imported into the Zabbix.

Link to the scanned host of Vuls.

Requirements　Zabbix >= 3.0.


## Setting cron


```bash:/etc/crontab
0 13 * * * vuls-user bash -l /opt/vuls/vuls_autoscan_for_zabbix.sh > /tmp/vuls.log 2>&1
```
## FAQ
Jq in EPEL is old (ver1.3).

Ex) Jq '[.KnownCves []?

Because "?" Can not be used, an error occurs.
You need to download and replace the ver1.5 binary at https://stedolan.github.io/jq/download/
