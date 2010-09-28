module S3
  # Class responsible for sending chunked requests
  # properly. Net::HTTPGenericRequest has hardcoded chunk_size, so we
  # inherit the class and override chunk_size.
  class Request < Net::HTTPGenericRequest
    def initialize(chunk_size, m, reqbody, resbody, path, initheader = nil)
      @chunk_size = chunk_size
      super(m, reqbody, resbody, path, initheader)
    end
  end
end
