# Identificando versão

require 'net/http'

def rails_version(url)
  response = Net::HTTP.get_response(URI(url))

  return false unless response.is_a?(Net::HTTPSuccess)

  if response.body =~ /application-\w{32}?\.js/
    [">=3.1", "<5.1"]
  elsif response.body =~ /application-\w{64}?\.js/
    [">=5.1"]
  end
end

url = ARGV[0]

puts url
puts rails_version(url).inspect
