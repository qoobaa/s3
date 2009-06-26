module S3
  class Object
    attr_accessor :key, :last_modified, :etag, :size, :bucket, :content, :content_type, :acl

    protected

    def initialize(options)
      @acl = options[:acl]
      @bucket = options[:bucket]
      @key = options[:key]
      @last_modified = options[:last_modified]
      @etag = options[:etag]
      @size = options[:size]
      @content = options[:content]
      @content_type = options[:content_type]
    end
  end
end
