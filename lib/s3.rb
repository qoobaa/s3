require "time"
require "openssl"
require "net/http"
require "net/https"
require "base64"
require "forwardable"
require "digest/md5"

require "xmlsimple"

require "s3/roxy/proxy"
require "s3/roxy/moxie"

require "s3/bucket"
require "s3/connection"
require "s3/exceptions"
require "s3/object"
require "s3/service"
require "s3/signature"

module S3
  # Default (and only) host serving S3 stuff
  HOST = "s3.amazonaws.com"
end
