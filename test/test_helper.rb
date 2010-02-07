require "rubygems"
gem "test-unit"
require "test/unit"
require "mocha"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "s3"
