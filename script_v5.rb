# Extraindo as lógicas de verificação

require 'net/http'
require 'digest'

OK = "✅"
NOK = "❌"

MATCHES = [
  # Asset pipeline
  { name: "Asset pipeline", type: :regexp, source: :body, value: /application-\w{32}?\.js/, version: [">=3.1", "<5.1"] },
  { name: "Asset pipeline", type: :regexp, source: :body, value: /application-\w{32}?\.css/, version: [">=3.1", "<5.1"] },
  { name: "Asset pipeline", type: :regexp, source: :body, value: /application-\w{64}?\.js/, version: [">=5.1"] },
  { name: "Asset pipeline", type: :regexp, source: :body, value: /application-\w{64}?\.css/, version: [">=5.1"] },

  # CSRF meta tag
  { name: "CSRF meta tag", type: :regexp, source: :body, value: /<meta name="csrf-token" content="/, version: [">=3.0.20"]},

  # Default session cookie name
  { name: "Default session cookie name", type: :regexp, source: :header, header: 'Set-Cookie', value: /_(.*)_session=/, version: [">2.3.14"]},

  # Error pages
  { name: "404 error page", type: :md5, source: :path, path: "/does_not_exit", value: "ac2e77894ac095b95ee94e5bb52eb89b", version: [">=3.0.20", "<4.0.0"] },
  { name: "404 error page", type: :md5, source: :path, path: "/does_not_exit", value: "f4d59d741048f0f72dc59c7cec8e4575", version: [">=4.0.0", "<4.1.0"] },
  { name: "404 error page", type: :md5, source: :path, path: "/does_not_exit", value: "6cc3545f1d476b4b4e9f0785b4811be5", version: [">=4.1.0", "<5.2.0"] },
  { name: "404 error page", type: :md5, source: :path, path: "/does_not_exit", value: "4ead20c186eaf2f7c09d6627ab7c0102", version: [">=5.2.0"] },

  # Phusion Passenger
  { name: "Phusion Passenger", type: :regexp, source: :header, header: "X-Powered-By", value: /Phusion Passenger/, version: [] },

  # Rails logo
  { name: "Rails logo", type: :md5, source: :path, path: "/assets/rails.png", value: "9c0a079bdd7701d7e729bd956823d153", version: ["<4.0.0"] },
]

def perform_match(match, source)
  case match[:type]
  when :regexp
    match_regexp(source, match[:value])
  when :md5
    match_md5(source, match[:value])
  else
    fail "Matcher not found: #{match[:type]}"
  end
end

def match_source(match, response)
  case match[:source]
  when :body
    response.body
  when :header
    response[match[:header]]
  when :path
    @response_cache ||= {}
    address = URI("#{response.uri.scheme}://#{response.uri.host}:#{response.uri.port}#{match[:path]}")
    @response_cache[address] ||= get(address).body
  else
    fail "Source not found: #{match[:source]}"
  end
end

def match_regexp(source, regexp)
  source =~ regexp
end

def match_md5(source, hash)
  Digest::MD5.hexdigest(source) == hash
end

def get(uri)
  Net::HTTP.get_response(uri)
end

def rails_version(uri)
  response = get(uri)

  MATCHES.map do |match|
    puts match.inspect

    source = match_source(match, response)
    result = perform_match(match, source)

    if result
      puts "#{OK} #{match[:version]}"
    else
      puts NOK
    end
  end
end

uri = URI(ARGV[0])
puts uri.inspect

rails_version(uri)
