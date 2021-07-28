# Adicionando um segundo teste

require 'net/http'

def rails?(url)
  response = Net::HTTP.get_response(URI(url))

  csrf_tag = '<meta name="csrf-param" content="authenticity_token" />'
  cookie_regexp = /_(.*)_session=/

  return false unless response.is_a?(Net::HTTPSuccess)

  response.body.include?(csrf_tag) && response['Set-Cookie'] =~ cookie_regexp
end

url = ARGV[0]

if rails?(url)
  puts "✅"
else
  puts "❌"
end

puts " #{url}"
