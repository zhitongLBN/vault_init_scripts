#!/bin/bash
#title           :init_vault_server.sh
#description     :This script will initialize a vault server and unseal it
#author		       :Zhitong LIU
#date            :20170213
#version         :0.1
#usage		       :bash init_vault_server.sh
#notes           :please install using the install.sh first
#==============================================================================
read -p "please enter the vault server address(format: address:port): " vault_address
echo ''

#### do not do anything if is already initalized
init_stat=`curl -s $vault_address/v1/sys/init | jq -r '.initialized'`

if [ $init_stat == "true" ]; then
  echo 'Vault is aready initialized'
  exit 1
fi

### initialize the vault with 3 secret key
# using 2 of them can unseal the vault
# https://www.vaultproject.io/docs/http/sys-init.html
echo "Initializing vault server: $vault_address"
echo "$vault_address" > ./root_token_and_keys

init_result=`curl -s -X PUT -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
	"secret_shares": 3,
	"secret_threshold": 2
}' "http://$vault_address/v1/sys/init"`

echo "results from vault init has been save into ./root_token_and_keys"
echo $init_result | jq
echo $init_result | jq >> ./root_token_and_keys

### recheck if vault is well initialized
init_stat=`curl -s $vault_address/v1/sys/init | jq -r '.initialized'`

if [ $init_stat == "false" ]; then
  echo 'Fail to init vault!!please retry later...exiting'
  exit 1
fi

root_token=`echo $init_result | jq -r '.root_token'`

### unseal the vault
seal_stat=`curl -s $vault_address/v1/sys/seal-status | jq -r '.sealed'`

if [ $init_stat == "false" ]; then
  echo 'vault already un sealed...exiting'
  exit 1
fi

echo 'Unsealing vault'

keys=`echo $init_result | jq -r '.keys'|sed 's/\[//g'|sed 's/\]//g'| sed 's/"//g' |sed 's/,//g'|sed 's/\ //g'`

# !!!!! if change the secret_threshold you loop this to get more key to unseal it
first_key=`echo $keys | sed -n '2p'`
second_key=`echo $keys | sed -n '3p'`

## using the first key to unseal
body="{
	"\"key\"": "\"$first_key\""
}"
first_result=`curl -X PUT -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d $body "http://$vault_address/v1/sys/unseal"`

## using the second key to unseal
body="{
	"\"key\"": "\"$second_key\""
}"
second_result=`curl -s -X PUT -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d $body "http://$vault_address/v1/sys/unseal"`

init_stat=`echo $second_result | jq -r '.sealed'`
if [ $init_stat == "false" ]; then
  echo 'The vault server has been initialized and unsealed successfully! GGWP'
else
  echo 'Vault still sealed, please contact your ops or author...exiting'
  exit 1
fi
