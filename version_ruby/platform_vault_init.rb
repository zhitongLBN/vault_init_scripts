require 'vault'
require 'pp'
require 'json'

platform = 'dev'
address = 'http://vault-server-address:8200'
root_token = 'root-token'

client = Vault::Client.new(address: address, token: root_token)

platform_admin_policy = {
  path: {
    # need this to list its policies, according to https://www.vaultproject.io/docs/http/sys-policy.html
    # filtre policy after
    'sys/policy': { capabilities: ['read', 'list'] },
    "sys/policy/#{platform}/*": { policy: 'sudo' },
    'auth/token/*': { policy: 'sudo' },
    "secret/#{platform}/*": { policy: 'sudo' },
  }
}

# this should be done by ops, and the wrapped.auth.client_token will be the secret in sd_service
client.sys.put_policy("#{platform}/admin", JSON.dump(platform_admin_policy))
platform_wrapped = client.auth_token.create(policies: ["#{platform}/admin"])

pp "please save these informations to platform #{platform}'s sd-service"
pp "sd_service type: vault"
pp "sd_service key_id: #{platform}"
pp "sd_service secret: #{platform_wrapped.auth.client_token}"

