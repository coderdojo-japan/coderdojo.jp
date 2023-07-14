#! /usr/bin/env ruby

system("ruby -v")
system("gem install bundler:2.4.7")
system("bundle install -j3 --quiet")

exec *ARGV