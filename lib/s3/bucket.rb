module S3
  class Bucket < Base
    attr_accessor :name

    def initialize(options)
      @name = options[:name]
      options[:host], @path_prefix = self.class.parse_name(options[:name], options[:host] || HOST)
      super
    end

    def self.parse_name(bucket_name, host)
      path_prefix = ""
      if "#{bucket_name}.#{host}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
        # VHOST
        host = "#{bucket_name}.#{host}"
      else
        # PATH BASED
        path_prefix = "/#{bucket_name}"
      end
      [host, path_prefix]
    end

    def location
      path = @path_prefix
      path << "/?location"

      request = Net::HTTP::Get.new(path)
      response = send_request(request)
      parse_location(response.body)
    end

    def exists?
      path = @path_prefix
      path << "/"

      request = Net::HTTP::Head.new(path)
      send_request(request)
      true
    end

    def delete(options = {})
      path = @path_prefix
      path << "/"

      request = Net::HTTP::Delete.new(path)
      send_request(request)
    end

    def save(options = {})
      location = options[:location]

      path = @path_prefix
      path << "/"

      request = Net::HTTP::Put.new(path)

      if location
        xml = "<CreateBucketConfiguration><LocationConstraint>#{location}</LocationConstraint></CreateBucketConfiguration>"
        request["content-type"] = "application/xml"
        request.body = xml
      end

      send_request(request)
    end

    def objects(options = {})
      path = @path_prefix
      path << "/"

      params = {}
      params["max-keys"] = options[:limit] if options.has_key?(:limit)
      params["prefix"] = options[:prefix] if options.has_key?(:prefix)
      params["marker"] = options[:marker] if options.has_key?(:marker)
      params["delimiter"] = options[:delimiter] if options.has_key?(:delimiter)

      joined_params = params.map { |key, value| "#{key}=#{value}" }.join("&")

      path << "?#{joined_params}" unless joined_params.empty?

      request = Net::HTTP::Get.new(path)
      response = send_request(request)
      parse_objects(response.body)
    end

    # OBJECT methods

    def build_object(options = {})
      Object.new(options.merge(:bucket => self))
    end

    def save_object(object)
      content_type = object.content_type
      content = object.content
      content_type ||= "application/octet-stream"
      acl = object.acl || "public-read"
      content = content.read if content.kind_of?(IO)

      path = @path_prefix
      path << "/"
      path << object.key

      request = Net::HTTP::Put.new(path)

      request["content-type"] = content_type
      request["x-amz-acl"] = acl
      request["content-md5"] = Base64.encode64(Digest::MD5.digest(content)).chomp

      request.body = content

      response = send_request(request)
    end

    def delete_object(object)
      path = @path_prefix
      path << "/"
      path << object.key

      request = Net::HTTP::Delete.new(path)

      response = send_request(request)
    end

    def get_object(object, options = {})
      path = @path_prefix
      path << "/"
      path << object.key

      request = Net::HTTP::Get.new(path)

      response = send_request(request)
    end

    private

    def parse_objects(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      objects_attributes = xml["Contents"]
      objects_attributes.map do |object|
        Object.new(:key => object["Key"],
                   :etag => object["ETag"],
                   :last_modified => object["LastModified"],
                   :size => object["Size"],
                   :bucket => self)
      end
    end

    def parse_location(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      xml["content"]
    end
  end
end
