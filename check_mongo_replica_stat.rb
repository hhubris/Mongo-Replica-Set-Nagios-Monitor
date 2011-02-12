#!/usr/bin/env ruby

require 'net/http'
require 'optparse'

@options = { :host => 'localhost', :port => 28017}

OptionParser.new do |opts|
  opts.on("-h", "--host [hostname]", "Hostname to connect to") do |v|
    @options[:host] = v
  end

  opts.on("-p", "--port [port]", "Port to connect to") do |v|
    @options[:port] = v
  end
end.parse!

begin
  resource = Net::HTTP.new(@options[:host], @options[:port])
  headers,data = resource.get('/replSetGetStatus?text')
rescue Exception => e
  puts "Unable to connect to #{host}:#{port} - #{e.message}"
  exit 2
end

# there has to be a better way to do this
data
  .gsub!(':', '=>')
  .gsub!('Date', '')


status = eval(data)

rc = 0
status['members'].each do |member|
  if member['state'] > 2
    print "ERROR: #{member['name']} state #{member['state']} "
    rc = 2
  end
end

if (rc == 0)
  puts 'ReplicaSet OK'
else
  puts ''
end

exit rc