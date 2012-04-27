#!/usr/bin/evn ruby
#
#A script to pull data from foreman and give us a report of a few things
#TO start:
#hostname, # patches avail, born_on, os release
#
#Usage:
#system_report.rb [ --compute [ --yaml | --json] ] 
#
#--compute:
# => queries compute nodes, instead of NON compute nodes, optional
#
#--yaml | --json:
# => outputs in yaml or json. Otherwise raw
require 'yaml'
require 'json'
require 'net/http'
require 'pp'
if (ARGV[0] == "-h" || ARGV[0] == "--help")
	        puts "Usage: system_report.rb [--compute]"
		puts "Prints a system report"
		puts ""
		puts "--compute: system report on compute nodes, instead of NON-compute nodes"
		puts "--yaml or --json: outputs in yaml or json, otherwise raw"
		exit
end

foreman="http://provisions.rc.fas.harvard.edu:3000"
hosts_search="#{foreman}/facts/compute_node/values?format=json"
puts "Getting host list...."
jhosts=JSON.parse(Net::HTTP.get(URI.parse(hosts_search)))

puts "Filtering host list..."
hosts=Array.new
jhosts.each do |host,fact|
	if ((ARGV[0] == "--compute") or (ARGV[1] == "--compute"))
		if (fact["compute_node"] =="true")
			hosts.push(host)
		end
	else
		if (fact["compute_node"] =="false")
			hosts.push(host)
		end
	end
end
puts "Found #{hosts.length} hosts"
puts "Getting facts for each host..."
yhosts=Array.new
#Now we need to get the info we want for each host...hm. 
hosts.each do |host|
	facts_search="#{foreman}/hosts/#{host}/facts?format=json"
	facts=JSON.parse(Net::HTTP.get(URI.parse(facts_search)))
	facts=facts[host]
	if ( facts["yum_updates_avail"].nil? )
		patches="0"
	else
		patches=facts["yum_updates_avail"].to_s
	end
	osrelease=facts["operatingsystemrelease"].to_s
	bornon=facts["born_on"].to_s
	yhost = { 	"hostname" => host,
			"born_on" => bornon,
			"osrelease" => osrelease,
			"patches_avail" => patches
	}
	yhosts.push(yhost)
end

yhosts.each do |host|
	if (host["patches_avail"] != 0)
		if ((ARGV[0] == "--yaml") or (ARGV[1] == "--yaml"))
			puts host.to_yaml
		elsif ((ARGV[0] == "--json") or (ARGV[1] == "--json"))
			puts host.to_json
		else
			puts host
		end
	end
end
