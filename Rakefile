$:.unshift File.expand_path("../lib", __FILE__)

require "rubygems"
require "rubygems/specification"
require "rake/testtask"
require "rake/rdoctask"
require "rake/gempackagetask"
require "s3"

def gemspec
  file = File.expand_path('../s3.gemspec', __FILE__)
  eval(File.read(file), binding, file)
end

Rake::TestTask.new(:test) do |test|
  test.libs << "lib" << "test"
  test.pattern = "test/**/*_test.rb"
  test.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "s3 #{S3::VERSION}"
  rdoc.rdoc_files.include("README.rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end

desc "Install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

task :gem => :gemspec
task :default => :test
