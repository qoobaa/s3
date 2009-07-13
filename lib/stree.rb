require "time"
require "openssl"
require "net/http"
require "net/https"
require "base64"
require "forwardable"
require "digest/md5"

require "xmlsimple"

require "stree/roxy/proxy"
require "stree/roxy/moxie"

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
