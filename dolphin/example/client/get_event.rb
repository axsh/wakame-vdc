require 'net/http'
require 'uri'
require 'multi_json'
require 'time'

start_time = URI.encode((Time.now - 60).iso8601)

path = 'http://127.0.0.1:9004/events'
# path = "http://127.0.0.1:9004/events?limit=10&start_time=#{start_time}"
# path = 'http://127.0.0.1:9004/events?start_id=12174a14-87c1-11e2-927c-31035db8d436'

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
