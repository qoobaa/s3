# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{s3}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jakub Kuźma", "Mirosław Boruta"]
  s.date = %q{2009-07-02}
  s.default_executable = %q{s3cmd.rb}
  s.email = %q{qoobaa@gmail.com}
  s.executables = ["s3cmd.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/s3cmd.rb",
     "lib/s3.rb",
     "lib/s3/bucket.rb",
     "lib/s3/connection.rb",
     "lib/s3/exceptions.rb",
     "lib/s3/object.rb",
     "lib/s3/roxy/moxie.rb",
     "lib/s3/roxy/proxy.rb",
     "lib/s3/service.rb",
     "lib/s3/signature.rb",
     "test/bucket_test.rb",
     "test/s3_test.rb",
     "test/signature_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/qoobaa/s3}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Library for accessing S3 objects and buckets, with command line tool}
  s.test_files = [
    "test/s3_test.rb",
     "test/bucket_test.rb",
     "test/signature_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
