#!/usr/bin/env ruby
#
#Simple script to bring a bunch of repos (svn and git) uptodate
#
require 'git'

#svn_repos=Array.new
git_repso=Array.new

#svn_repos=["puppet"]
git_repos=["puppet.git","pam_radius","admin","docs","sjoeboo.github.com","dotfiles"]

#svn_repos.each do |svn_repo|
#	svn_cmd = "svn up #{svn_repo}"
#	puts "Now Updating repo: #{svn_repo}"
#	output = %x[#{svn_cmd}]
#	puts output
	#output.each do |out|
	#	puts out.chomp!
	#end
#end

git_repos.each do |git_repo|
	#Do stuff, hopefully with git bindings!
	puts "Now Updating repo: #{git_repo}"
	#g = Git.open(git_repo)
	#g.pull
	git_cmd = "cd #{git_repo} && git pull"
	output = %x[#{git_cmd}]
	puts output
end
