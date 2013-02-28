require 'net/http'
require 'uri'
require 'json'

methods = ['post'].freeze

method = ARGV[0]

unless methods.include?(method)
  puts "Not found method: #{method}"
  exit
end

mail_to ||= ENV['MAIL_TO']
mail_cc ||= ENV['MAIL_CC']
mail_bcc ||= ENV['MAIL_BCC']

path = 'http://127.0.0.1:3000/notifications'
uri = URI.parse(path)

headers = {
  'Content-Type' =>'application/json',
  'X-NOTIFICATION-ID' => 'system',
}

methods = {
  'mail' => {
    'subject' => 'Test Mail',
    'to' => mail_to,
    'cc' => mail_cc,
    'bcc' => mail_bcc,
  }
}

request = Net::HTTP::Post.new(uri.request_uri, headers)
request.body = methods.to_json

http = Net::HTTP.new(uri.host, uri.port)
http.set_debug_output $stderr
http.start do |h|
  response = h.request(request)
  puts response.body
end

