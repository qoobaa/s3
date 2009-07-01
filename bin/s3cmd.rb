#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__) + "/../lib")

require "trollop"
require "s3"

include S3

COMMANDS = %w(make)

global_options = Trollop::options do
  banner "s3.rb"
  opt :access_key_id, "Your access key id to AWS", :required => true, :type => String
  opt :secret_access_key, "Your secret access key to AWS", :required => true, :type => String
  stop_on COMMANDS
end

service = Service.new(:access_key_id => global_options[:access_key_id],
                      :secret_access_key => global_options[:secret_access_key])

command = ARGV.shift

begin
  case command
  when "list"
    command_options = Trollop::options do
      banner "list buckets"
    end
    service.buckets.each do |bucket|
      puts bucket.name
    end
  when "make"
    command_options = Trollop::options do
      banner "make bucket"
      opt :location, "Location of the bucket - currently EU or US", :default => "US"
    end
    name = ARGV.shift
    bucket = service.buckets.build(name)
    Trollop::die "problems with creating bucket" unless bucket.save(command_options[:location])
  when "remove"
    command_options = Trollop::options do
      banner "make bucket"
    end
    name = ARGV.shift
    bucket = service.buckets.find(name)
    Trollop::die "problems with creating bucket" unless bucket.destroy
  when nil
    Trollop::die "no command"
  else
    Trollop::die "unknown command #{command.inspect}"
  end
rescue Error::ResponseError => e
  Trollop::die e.message.sub(/\.+\Z/, "")
end
