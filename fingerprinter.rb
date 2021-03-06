require 'net/http'
require 'json'
require 'digest'

OK = "✅"
NOK = "❌"
VERSIONS_LOCATION = "https://rubygems.org/api/v1/versions/rails.json"
VERSIONS_FILE = "versions.tmp"

MATCHES = [
  # Asset pipeline
  { name: "Asset pipeline JS with 32 chars", type: :regexp, source: :body, value: /-[a-f0-9]{32}?\.js/, version: [">=3.1", "<5.1"] },
  { name: "Asset pipeline CSS with 32 chars", type: :regexp, source: :body, value: /-[a-f0-9]{32}?\.css/, version: [">=3.1", "<5.1"] },
  { name: "Asset pipeline JS with 64 chars", type: :regexp, source: :body, value: /-[a-f0-9]{64}?\.js/, version: [">=5.1"] },
  { name: "Asset pipeline CSS with 64 chars", type: :regexp, source: :body, value: /-[a-f0-9]{64}?\.css/, version: [">=5.1"] },

  # CSRF meta tag
  { name: "CSRF meta tag", type: :regexp, source: :body, value: /<meta name="csrf-token" content="/, version: [">=3.0.20"]},

  # Default session cookie name
  { name: "Default session cookie name", type: :regexp, source: :header, header: 'Set-Cookie', value: /_(.*)_session=/, version: [">0.0.0"]},

  # Error pages
  { name: "404 error page v1", type: :md5, source: :path, path: "/does_not_exit", value: "ac2e77894ac095b95ee94e5bb52eb89b", version: [">=3.0.20", "<4.0.0"] },
  { name: "404 error page v2", type: :md5, source: :path, path: "/does_not_exit", value: "f4d59d741048f0f72dc59c7cec8e4575", version: [">=4.0.0", "<4.1.0"] },
  { name: "404 error page v3", type: :md5, source: :path, path: "/does_not_exit", value: "6cc3545f1d476b4b4e9f0785b4811be5", version: [">=4.1.0", "<5.2.0"] },
  { name: "404 error page v4", type: :md5, source: :path, path: "/does_not_exit", value: "4ead20c186eaf2f7c09d6627ab7c0102", version: [">=5.2.0"] },

  # Phusion Passenger
  { name: "Phusion Passenger", type: :regexp, source: :header, header: "X-Powered-By", value: /Phusion Passenger/, version: [">0.0.0"] },

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
    raise "Matcher not found: #{match[:type]}"
  end
end

def match_source(match, response, location)
  case match[:source]
  when :body
    response.body
  when :header
    response[match[:header]]
  when :path
    @response_cache ||= {}
    uri = URI(location)
    address = URI("#{uri.scheme}://#{uri.host}:#{uri.port}#{match[:path]}")
    @response_cache[address] ||= get(address, false).body
  else
    raise "Source not found: #{match[:source]}"
  end
end

def match_regexp(source, regexp)
  source =~ regexp
end

def match_md5(source, hash)
  Digest::MD5.hexdigest(source) == hash
end

def get(location, follow_redirect=true, limit=10)
  raise ArgumentError, "Too many HTTP redirects" if limit == 0

  uri = URI(location)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == "https"
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  case response
  when follow_redirect && Net::HTTPRedirection
    location = response['location']
    warn "Redirected to #{location}"
    get(location, limit - 1)
  else
    response
  end
end

def perform_matches(location)
  response = get(location)

  MATCHES.map do |match|
    source = match_source(match, response, location)
    result = perform_match(match, source)

    { match: match, result: result }
  end
end

def print_results(results)
  column_size = MATCHES.map { |m| m[:name].size }.max + 1

  results.each do |result|
    print result[:match][:name].ljust(column_size)

    if result[:result]
      puts "#{OK} #{result[:match][:version]}"
    else
      puts "#{NOK}"
    end
  end
end

def generate_rails_versions_array
  if File.exist?(VERSIONS_FILE) && !File.zero?(VERSIONS_FILE)
    print "Retrieving cache"
    content = File.open(VERSIONS_FILE).read
  else
    print "Caching versions"
    content = get(VERSIONS_LOCATION).body
    File.open(VERSIONS_FILE, "w").write(content)
  end

  versions = JSON.parse(content).map { |release| Gem::Version.new(release["number"]) }
  puts " (#{versions.size} releases)"

  versions
end

def predicted_versions(results)
  rails_versions = generate_rails_versions_array
  positive_results = results.find_all{ |result| result[:result] }

  return [] if positive_results.empty?

  positive_results.each do |result|
    result[:match][:version].each do |match_version|
      rails_versions.reject! do |rails_version|
        !Gem::Dependency.new('rails', match_version).match?('rails', rails_version)
      end
    end
  end

  rails_versions.sort
end

def print_versions(versions)
  if versions.empty?
    puts "Could not predict Rails version"
  else
    puts "Predicted Rails versions (#{versions.size} releases): "
    puts versions.join(", ")
  end
end

location = ARGV[0]
results = perform_matches(location)
print_results(results)

puts "\n"

versions = predicted_versions(results)
print_versions(versions)