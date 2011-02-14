#!/usr/bin/env ruby

#   Copyright (C) 2011 Tony Nelson
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

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
  puts "ERROR: Unable to connect to #{@options[:host]}:#{@options[:port]} - #{e.message}"
  exit 2
end

# there has to be a better way to do this
data.gsub!(':', '=>')
data.gsub!('Date', '')

begin
  status = eval(data)
rescue Exception => e
  puts "ERROR: Unable to eval result from server"
  exit 2
end

rc = 0
have_master = false
status['members'].each do |member|
  if member['state'] > 2
    print "ERROR: #{member['name']} state #{member['state']} "
    rc = 2
  end

  have_master |= (member['state'] == 1)
end

if (!have_master)
  puts "ERROR: No master detected"
  rc = 2
elsif (rc == 0)
  puts 'ReplicaSet OK'
else
  puts ''
end

exit rc
