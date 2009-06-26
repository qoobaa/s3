module S3
  class Bucket < Base
    attr_accessor :name

    def initialize(options)
      @name = options[:name]
      options[:host], options[:path_prefix] = self.class.parse_name(options[:name], options[:host] || HOST)
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
      response = get("/", { :location => nil })
      parse_location(response.body)
    end

    def exists?
      response = head("/")
    end

    def destroy(options = {})
      response = delete("/")
    end

    def save(options = {})
      headers = {}
      if options[:location]
        body = "<CreateBucketConfiguration><LocationConstraint>#{options[:location]}</LocationConstraint></CreateBucketConfiguration>"
        headers[:content_type] = "application/xml"
      end
      put("/", body, headers)
    end

    def objects(options = {})
      response = get("/", options)
      parse_objects(response.body)
    end

    # OBJECT methods

    def build_object(options = {})
      Object.new(options.merge(:bucket => self))
    end

    def save_object(object)
      headers = {}
      headers[:content_type] = object.content_type
      headers[:x_amz_acl] = object.acl

      body = object.content
      body = body.read if body.kind_of?(IO)

      response = put("/#{object.key}", body, headers)
    end

    def destroy_object(object)
      response = delete("/#{object.key}")
    end

    def get_object(object, options = {})
      response = get("/#{object.key}", options)
    end

    def get_object_info(object)
      response = head("#{object.key}")
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
