# -*- encoding: utf-8 -*-

# Load version requiring the canonical "s3/version", otherwise Ruby will think
# is a different file and complaint about a double declaration of S3::VERSION.
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "s3/version"

Gem::Specification.new do |s|
  s.name        = "s3"
  s.version     = S3::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kuba Kuźma"]
  s.email       = ["kuba@jah.pl"]
  s.homepage    = "http://github.com/qoobaa/s3"
  s.summary     = "Library for accessing S3 objects and buckets"
  s.description = "S3 library provides access to Amazon's Simple Storage Service. It supports both: European and US buckets through REST API."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "s3"

  s.add_dependency "proxies", "~> 0.2.0"
  s.add_development_dependency "test-unit", ">= 2.0"
  s.add_development_dependency "mocha"
  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = "lib"
end
