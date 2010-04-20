# -*- coding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "s3"
  s.version = S3::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jakub Kuźma"]
  s.email = "qoobaa@gmail.com"
  s.homepage = "http://jah.pl/projects/s3.html"
  s.summary = "Library for accessing S3 objects and buckets, with command line tool"
  s.description = "S3 library provides access to Amazon's Simple Storage Service. It supports both: European and US buckets through REST API."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "trollop"
  s.add_dependency "proxies"
  s.add_development_dependency "test-unit", ">= 2.0"
  s.add_development_dependency "mocha"

  s.files = Dir.glob("{bin,extra,lib}/**/*") + %w(LICENSE README.rdoc)
  s.executables  = ["s3"]
end
