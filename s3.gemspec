# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "s3/version"

Gem::Specification.new do |spec|
  spec.name          = "s3"
  spec.version       = S3::VERSION
  spec.authors       = ["Kuba Kuźma"]
  spec.email         = ["kuba@jah.pl"]

  spec.summary       = "Library for accessing S3 objects and buckets"
  spec.description   = "S3 library provides access to Amazon's Simple Storage Service."
  spec.homepage      = "http://github.com/qoobaa/s3"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "mocha"
  spec.add_dependency "addressable"
  spec.add_dependency "proxies"
end
