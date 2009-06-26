module S3
  class Service < Base
    def buckets
      request = Net::HTTP::Get.new("/")
      response = send_request(request)
      parse_buckets(response.body)
    end

    private

    def parse_buckets(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      buckets_names = xml["Buckets"].first["Bucket"].map { |bucket| bucket["Name"].first }
      buckets_names.map do |bucket_name|
        Bucket.new(:name => bucket_name,
                   :access_key_id => access_key_id,
                   :secret_access_key => secret_access_key,
                   :host => host,
                   :use_ssl => use_ssl)
      end
    end
  end
end

