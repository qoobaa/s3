module S3
  class Service
    HOST = "s3.amazonaws.com"
    PORT = 80

    def initialize(options)
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
    end

    def buckets
      request = Net::HTTP::Get.new("/")

      http = Net::HTTP.new(HOST, PORT)
      http.set_debug_output(STDOUT)
      http.start do |http|
        host = http.address
        request['Date'] ||= Time.now.httpdate
        request["Authorization"] = S3::Signature.generate(:host => host,
                                                          :request => request,
                                                          :access_key_id => @access_key_id,
                                                          :secret_access_key => @secret_access_key)
        http.request(request)
      end
    end

  end
end

