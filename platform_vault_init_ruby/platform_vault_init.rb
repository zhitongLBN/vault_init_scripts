require 'vault'
require 'pp'
require 'json'

puts "Begin to initial environnement for a platform on vault for Selfdeploy"
puts "Please enter the Platform's name(Case Sensitive): "
platform = gets.chomp
puts ''
puts "Please enter the Vault server's address(http://addresss:port): "
address = gets.chomp
puts ''
puts "Please enter the root token of this Vault server: "
root_token = gets.chomp
puts ''

client = Vault::Client.new(address: address, token: root_token)

platform_admin_policy = {
  path: {
    # need this to list its policies, according to https://www.vaultproject.io/docs/http/sys-policy.html
    # filtre policy after
    'sys/policy': { capabilities: ['read', 'list'] },
    "sys/policy/#{platform}/*": { policy: 'sudo' },
    'auth/token/*': { policy: 'sudo' },
    "secret/#{platform}/*": { policy: 'sudo' },
    "secret/#{platform}": { policy: 'sudo' }
  }
}

# this should be done by ops, and the wrapped.auth.client_token will be the secret in sd_service
client.sys.put_policy("#{platform}/admin", JSON.dump(platform_admin_policy))
platform_wrapped = client.auth_token.create(policies: ["#{platform}/admin"])

puts "Please save these informations to platform #{platform}'s sd-service!!!"
puts "  sd_service type:   vault"
puts "  sd_service key_id: #{platform}"
puts "  sd_service secret: #{platform_wrapped.auth.client_token}"

puts "these information has been save into ./platform_keys"

begin
  file = File.open("./platform_keys", "w") do |f|
    f << "#{address}\n"
    f << "#{platform}\n"
    f << "#{platform_wrapped.auth.client_token}\n"
    f << "\n"
  end
rescue IOError
  #some error occur, dir not writable etc.
  puts "File can not be write!"
ensure
  file.close unless file.nil?
end
