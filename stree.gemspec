# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{stree}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jakub Kuźma", "Mirosław Boruta"]
  s.date = %q{2009-07-13}
  s.default_executable = %q{stree}
  s.email = %q{qoobaa@gmail.com}
  s.executables = ["stree"]
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
     "bin/stree",
     "extra/stree_backend.rb",
     "lib/stree.rb",
     "lib/stree/bucket.rb",
     "lib/stree/connection.rb",
     "lib/stree/exceptions.rb",
     "lib/stree/object.rb",
     "lib/stree/roxy/moxie.rb",
     "lib/stree/roxy/proxy.rb",
     "lib/stree/service.rb",
     "lib/stree/signature.rb",
     "stree.gemspec",
     "test/bucket_test.rb",
     "test/connection_test.rb",
     "test/object_test.rb",
     "test/service_test.rb",
     "test/signature_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/qoobaa/stree}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Library for accessing S3 objects and buckets, with command line tool}
  s.test_files = [
    "test/bucket_test.rb",
     "test/service_test.rb",
     "test/signature_test.rb",
     "test/connection_test.rb",
     "test/test_helper.rb",
     "test/object_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<trollop>, [">= 1.14"])
    else
      s.add_dependency(%q<trollop>, [">= 1.14"])
    end
  else
    s.add_dependency(%q<trollop>, [">= 1.14"])
  end
end
