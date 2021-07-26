# Extraindo as lógicas de verificação

require 'net/http'

OK = "✅"
NOK = "❌"

MATCHES = [:csrf_tag, :default_cookie_name, :application_js, :application_css]

def has_csrf_tag?(response)
  csrf_tag = '<meta name="csrf-param" content="authenticity_token" />'
  response.body.include?(csrf_tag)
end

def has_default_cookie_name?(response)
  cookie_regexp = /_(.*)_session=/
  response['Set-Cookie'] =~ cookie_regexp
end

def has_application_js?(response)
  response.body =~ /application-\w{64}?\.js/
end

def has_application_css?(response)
  response.body =~ /application-\w{64}?\.css/
end

def rails?(url)
  response = Net::HTTP.get_response(URI(url))

  return false unless response.is_a?(Net::HTTPSuccess)

  puts url

  MATCHES.each do |match|
    match_result = send("has_#{match}?", response)
    puts "  #{match_result ? OK : NOK} #{match}"
  end
end

url = ARGV[0]
rails?(url)