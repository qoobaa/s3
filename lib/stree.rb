require "base64"
require "digest/md5"
require "forwardable"
require "net/http"
require "net/https"
require "openssl"
require "rexml/document"
require "time"

require "stree/roxy/moxie"
require "stree/roxy/proxy"

require "stree/parser"
require "stree/bucket"
require "stree/connection"
require "stree/exceptions"
require "stree/object"
require "stree/service"
require "stree/signature"

module Stree
  # Default (and only) host serving S3 stuff
  HOST = "s3.amazonaws.com"
end
