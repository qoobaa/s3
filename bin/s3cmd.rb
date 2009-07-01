#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__) + "/../lib")

require "trollop"
require "s3"

include S3

def list_buckets(service)
  service.buckets.each do |bucket|
    puts bucket.name
  end
end

def create_bucket(service, name, location)
  service.buckets.build(name).save(location)
end

def destroy_bucket(service, name)
  service.buckets.find(name).destroy
end

def show_bucket(service, name, options = {})
  service.buckets.find(name).objects.find(options).each do |object|
    puts object.key
  end
end

def list_objects(service)
  service.buckets.each do |bucket|
    bucket.objects.each do |object|
      puts "#{bucket.name}/#{object.key}"
    end
  end
end

ACCESS_KEY_ID = ENV["ACCESS_KEY_ID"]
SECRET_ACCESS_KEY = ENV["SECRET_ACCESS_KEY"]
COMMANDS = %w(bucket object)
BUCKET_SUBCOMMANDS = %w(add remove show)
OBJECT_SUBCOMMANDS = %w(add remove)

global_options = Trollop::options do
  banner "s3.rb"
  opt :access_key_id, "Your access key id to AWS", :type => String, :default => ACCESS_KEY_ID
  opt :secret_access_key, "Your secret access key to AWS", :type => String, :default => SECRET_ACCESS_KEY
  opt :debug, "Debug mode", :type => :flag, :default => false
  stop_on COMMANDS
end

Trollop::die "No access key id given" unless global_options[:access_key_id]
Trollop::die "No secret access key given" unless global_options[:secret_access_key]

service = Service.new(:access_key_id => global_options[:access_key_id],
                      :secret_access_key => global_options[:secret_access_key],
                      :debug => global_options[:debug])

command = ARGV.shift

begin
  case command
  when "bucket"
    command_options = Trollop::options do
      banner "manage buckets"
      stop_on BUCKET_SUBCOMMANDS
    end
    subcommand = ARGV.shift
    case subcommand
    when "add"
      subcommand_options = Trollop::options do
        opt :location, "Location of the bucket - EU or US", :default => "US", :type => String
      end
      name = ARGV.shift
      Trollop::die "Bucket has not been added because of unknown error" unless create_bucket(service, name, subcommand_options[:location])
    when "remove"
      name = ARGV.shift
      Trollop::die "Bucket name must be given" if name.nil? or name.empty?
      Trollop::die "Bucket has not been removed because of unknown error" unless destroy_bucket(service, name)
    when "show"
      subcommand_options = Trollop::options do
        opt :prefix, "Limits the response to keys which begin with the indicated prefix", :type => String
        opt :marker, "Indicates where in the bucket to begin listing", :type => String
        opt :max_keys, "The maximum number of keys you'd like to see", :type => Integer
        opt :delimiter, "Causes keys that contain the same string between the prefix and the first occurrence of the delimiter to be rolled up into a single result element", :type => String
      end
      name = ARGV.shift
      Trollop::die "Bucket name must be given" if name.nil? or name.empty?
      show_bucket(service, name, subcommand_options)
    when nil
      list_buckets(service)
    else
      Trollop::die "Unknown subcommand: #{subcommand.inspect}"
    end
  when "object"
    command_options = Trollop::options do
      banner "manage objects"
      stop_on OBJECT_SUBCOMMANDS
    end
    subcommand = ARGV.shift
    case subcommand
    when "add"

    when "remove"

    when nil
      list_objects(service)
    else
      Trollop::die "Unknown subcommand: #{subcommand.inspect}"
    end
  else
    Trollop::die "Unknown command #{command.inspect}"
  end
rescue Error::ResponseError => e
  Trollop::die e.message.sub(/\.+\Z/, "")
end
