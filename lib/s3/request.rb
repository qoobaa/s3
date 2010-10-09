module S3
  # Class responsible for sending chunked requests
  # properly. Net::HTTPGenericRequest has hardcoded chunk_size, so we
  # inherit the class and override chunk_size.
  class Request < Net::HTTPGenericRequest
    def initialize(chunk_size, m, reqbody, resbody, path, initheader = nil)
      @chunk_size = chunk_size
      super(m, reqbody, resbody, path, initheader)
    end

    private

    def send_request_with_body_stream(sock, ver, path, f)
      unless content_length() or chunked?
        raise ArgumentError, "Content-Length not given and Transfer-Encoding is not `chunked'"
      end
      supply_default_content_type
      write_header sock, ver, path
      if chunked?
        while s = f.read(@chunk_size)
          sock.write(sprintf("%x\r\n", s.length) << s << "\r\n")
        end
        sock.write "0\r\n\r\n"
      else
        while s = f.read(@chunk_size)
          sock.write s
        end
      end
    end
  end
end
