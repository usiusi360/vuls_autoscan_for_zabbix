# vuls_autoscan_for_zabbix #

vuls_autoscan_for_zabbix can work together the contents [Vuls](https://github.com/future-architect/vuls) detects to zabbix.

## Abstract

vuls_autoscan_for_zabbix is performed as follows.

* create_config.sh
1. Automatically generate config.toml from Zabbix

* vuls_autoscan_for_zabbix.sh
2. Vulnerability information (NVD / JVN / OVAL) update
3. Vuls scan & report
4. Result cooperation to Zabbix
5. Rotation of Vuls JSON file


## Installation

Put shell script to "Home Folder" on Vuls.
And set the execution authority.


```
$ cd /opt/vuls
$ wget https://github.com/usiusi360/vuls_autoscan_for_zabbix/create_config.sh
$ wget https://github.com/usiusi360/vuls_autoscan_for_zabbix/vuls_autoscan_for_zabbix.sh
$ chmod 700 create_config.sh vuls_autoscan_for_zabbix.sh
```


Change the address, ID, and password of the Zabbix server in the script according to the environment.

```
$ vi create_config.sh
---------
ZABBIX_SERVER="localhost"
ZABBIX_USER="Admin"
ZABBIX_PASS="hogehoge"
```


```
$ vi vuls_autoscan_for_zabbix.sh
---------
ZABBIX_SERVER="localhost"
```

If you jq and zabbix-sender is not installed, you must install.


```
$ yum install jq zabbix-sender
```

## Create config.toml

Create a master file.

```
$ cd /opt/vuls
$ vi config.toml.master
[default]
port        = "22"
user        = "username"
keyPath     = "/home/username/.ssh/id_rsa"

$ chmod 700 create_config.sh
```


Running create_config.sh will generate config.toml.

```
$ ./create_config.sh

$ cat config.toml
[default]
port        = "22"
user        = "username"
keyPath     = "/home/username/.ssh/id_rsa"

[servers]
[servers.web001]
host        = "192.168.0.1"

[servers.app001]
host        = "192.168.0.2"
　　　～～～～
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
