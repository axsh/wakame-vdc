require 'net/http'
require 'uri'
require 'multi_json'
require 'pry'

path = 'http://127.0.0.1:3000/events?start=0&limit=10'
uri = URI.parse(path)

headers = {
  'Content-Type' =>'application/json',
}

request = Net::HTTP::Get.new(uri.request_uri, headers)
http = Net::HTTP.new(uri.host, uri.port)
http.set_debug_output $stderr
http.start do |h|
  response = h.request(request)
  res = MultiJson.load(response.body)
  p res
end
