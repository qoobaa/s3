module S3
  class Bucket
    extend Forwardable

    attr_reader :name

    def location
      response = connection.get(:path => "/", :params => { :location => nil }, :host => host)
      parse_location(response.body)
    end

    def exists?
      response = head("/")
    end

    def destroy(options = {})
      response = delete("/")
    end

    # def save(options = {})
    #   headers = {}
    #   if options[:location]
    #     body = "<CreateBucketConfiguration><LocationConstraint>#{options[:location]}</LocationConstraint></CreateBucketConfiguration>"
    #     headers[:content_type] = "application/xml"
    #   end
    #   put("/", body, headers)
    # end

    def objects(options = {})
      response = get("/", options)
      parse_objects(response.body)
    end

    protected

    def_instance_delegators :@service, :connection

    def initialize(service, name)
      @service = service
      @name = name
    end

    private

    def vhost?
      "#@name.#{HOST}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
    end

    def path_prefix
      vhost? ? "/#@name" : ""
    end

    def host
      vhost? ? "#@name.#{HOST}" : "#{HOST}"
    end

    # def build_object(options = {})
    #   Object.new(options.merge(:bucket => self))
    # end

    # def save_object(object)
    #   headers = {}
    #   headers[:content_type] = object.content_type
    #   headers[:x_amz_acl] = object.acl

    #   body = object.content
    #   body = body.read if body.kind_of?(IO)

    #   response = put("/#{object.key}", body, headers)
    # end

    # def destroy_object(object)
    #   response = delete("/#{object.key}")
    # end

    # def get_object(object, options = {})
    #   response = get("/#{object.key}", options)
    # end

    # def get_object_info(object)
    #   response = head("/#{object.key}")
    # end

    # def parse_objects(xml_body)
    #   xml = XmlSimple.xml_in(xml_body)
    #   objects_attributes = xml["Contents"]
    #   objects_attributes.map do |object|
    #     Object.new(:key => object["Key"],
    #                :etag => object["ETag"],
    #                :last_modified => object["LastModified"],
    #                :size => object["Size"],
    #                :bucket => self)
    #   end
    # end

    def parse_location(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      xml["content"]
    end
  end
end
