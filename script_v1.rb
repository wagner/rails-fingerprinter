# Versão inicial

require 'net/http'

def rails?(url)
  response = Net::HTTP.get_response(URI(url))
  csrf_tag = '<meta name="csrf-param" content="authenticity_token" />'

  return false unless response.is_a?(Net::HTTPSuccess)

  response.body.include?(csrf_tag)
end

url = ARGV[0]

if rails?(url)
  puts "✅"
else
  puts "❌"
end
