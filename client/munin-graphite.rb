#!/usr/bin/env ruby
#
# graphite-mdash client - build ontop of munin-graphite
#
# Copyright: Copyright (c) 2012, Jonas Genannt <jonas@brachium-system.net>
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
#
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software
# Foundation; either version 2 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'optparse'
require 'socket'
require 'json'
require "net/http"
require "uri"
require 'syslog'

class Munin
  def initialize(host='127.0.0.1', port=4949)
    @munin = TCPSocket.new(host, port)
    @munin.gets
  end

  def get_response(cmd)
    @munin.puts(cmd)
    stop = false 
    response = Array.new
    while stop == false
      line = @munin.gets
      line.chomp!
      if line == '.'
        stop = true
      else
        response << line 
        stop = true if cmd == "list"
      end
    end
    response
  end

  def close
    @munin.close
  end
end

class Carbon
  def initialize(host='127.0.0.1', port=2003)
    @carbon = TCPSocket.new(host, port)
  end

  def send(msg)
    @carbon.puts(msg)
  end

  def close
    @carbon.close
  end
end

options = {
  :munin_node_host => '127.0.0.1',
  :munin_node_port => 4949,
  :carbon_host => '127.0.0.1',
  :carbon_port => 2003,
  :interval => 60,
  :runonce => false,
  :pidfile => '/var/run/munin-graphite.pid',
  :mdash_url => "http://localhost:3000/munin/update",
}

OptionParser.new do |opts|
  opts.banner = "Usage: munin-graphite.rb [options]"

  opts.on("-m", "--munin-node-host HOST", "munin Node host (default: #{options[:munin_node_host].to_s})") do |o|
    options[:munin_node_host] = o
  end
  opts.on("-p", "--munin-node-port PORT", "munin Node port (default: #{options[:munin_node_port].to_s})") do |o|
    options[:munin_node_port] = o.to_i
  end
  opts.on("-c", "--carbon-host HOST", "graphite/carbon Hostname (default: #{options[:carbon_host].to_s})") do |o|
    options[:carbon_host] = o
  end
  opts.on("-a", "--carbon-port PORT", "graphite/carbon port (default: #{options[:carbon_port].to_s})") do |o|
    options[:carbon_port] = o.to_i
  end
  opts.on("-r", "--runonce", "run graphite-munin once and exit. do not start as daemon") do |o|
    options[:runonce] = true
  end
  opts.on("-f", "--pidfile FILE", "pidfile for munin-graphite (default: #{options[:pidfile].to_s})") do |o|
    options[:pidfile] = o
  end
  opts.on("-i", "--interval INTERVAL", "interval in seconds to query munin-node and send stats to graphite/carbon (default: #{options[:interval].to_s})") do |o|
    options[:interval] = o.to_i
  end
  opts.on("-u", "--mdash-url URL", "URL to MDash Webinterface: http://your-server.com:3000/munin/update") do |o|
    options[:mdash_url] = o
  end
end.parse!

fork do
  Process.setsid
  exit if fork
  unless options[:runonce]
    File.open(options[:pidfile], 'w') {|f| f.write(Process.pid) }
    Dir.chdir('/')
  end
  mdash_send = 0

  while true
    begin
      metric_base = "servers."
      all_metrics = Array.new
      plugin_config = Hash.new
      mdash_send_now = false

      # push plugin config only once per hour and on startup, saves cpu time on node and master!
      if mdash_send + 3600 < Time.now.to_i
        mdash_send_now = true
        mdash_send = Time.now.to_i
      end

      munin = Munin.new(options[:munin_node_host], options[:munin_node_port])
      munin.get_response("nodes").each do |node|
        plugin_config[node] = Hash.new
        metric_base << node.split(".").reverse.join(".")
      
        munin.get_response("list")[0].split(" ").each do |metric|
          metric_base_clean = metric_base.to_s
          metric_clean      = metric.gsub(/\./, '_')

          if mdash_send_now
            config = Array.new
            munin.get_response("config #{metric}").each do |line|
              config << line.strip
            end
            plugin_config[node][metric] = { 'name_clean' => metric_clean, 'config' => config }
            config = nil
          end

          munin.get_response("fetch #{metric}").each do |line|
            line =~ /^(.+)\.value\s+(.+)$/
            field = $1
            value = $2
            field_clean = field.to_s.gsub(/\./, '_')
            all_metrics << "#{metric_base_clean}.#{metric_clean}.#{field_clean} #{value} #{Time.now.to_i}"
          end
        end
      end
      munin.close
      
      carbon = Carbon.new(options[:carbon_host], options[:carbon_port])
      all_metrics.each do |m|
        carbon.send(m)
      end
      carbon.close
      
      if mdash_send_now
        uri = URI.parse(options[:mdash_url])
        res = Net::HTTP.post_form(uri, {"json" => plugin_config.to_json})
        if res.code.to_i != 200
          Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |d| d.warning "Response to MDash was #{res.code}" }
        end
      end
    
      if options[:runonce] == true
        Process.exit!
      end
    rescue  Exception => e
      if options[:runonce] == true
        puts e.message
        exit
      else
        Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |d| d.warning "Munin Graphite: #{e.message}" }
      end
    end
    sleep options[:interval]
  end
end
