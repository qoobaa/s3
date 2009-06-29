require "time"
require "openssl"
require "net/http"
require "net/https"
require "base64"
require "forwardable"
require "digest/md5"

require "xmlsimple"

require "s3/bucket"
require "s3/connection"
require "s3/exceptions"
require "s3/object"
require "s3/service"
require "s3/signature"

module S3
  HOST = "s3.amazonaws.com"
end
