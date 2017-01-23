# Platform initialization for vault
this script is to generate new creds for a new selfdeploy platform on vault

run
> sudo ./version_ruby/install.sh
> ruby verison_ruby/platform_vault_init.rb

then provide information

## Information u will need
vault server address

vault server root token

new platform's name

## After
it will return a new token for the new platform, please put it into sd_service

key_id: new platform's name

secret: new token from script

# Done GG WP
