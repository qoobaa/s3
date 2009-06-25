module S3
  class Service
    HOST = "data.synergypeople.net.s3.amazonaws.com"
    PORT = 80

    def initialize(options)
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
    end

    def buckets
      request = Net::HTTP::Get.new("/")

      http_verb = request.method
      content_md5 = ""
      content_type = ""
      date = request["Date"]

      # http = Net::HTTP.new(HOST, PORT)
      # http.set_debug_output(STDOUT)
      # http.start do |http|

      #   http.request(request)
      # end
    end

    def canonicalized_amz_headers(request)
      headers = []

      # 1. Convert each HTTP header name to lower-case. For example,
      # 'X-Amz-Date' becomes 'x-amz-date'.
      request.each { |key, value| headers << [key.downcase, value] if key =~ /\Ax-amz-/io }
      #=> [["c", 0], ["a", 1], ["a", 2], ["b", 3]]

      # 2. Sort the collection of headers lexicographically by header
      # name.
      headers.sort!
      #=> [["a", 1], ["a", 2], ["b", 3], ["c", 0]]

      # 3. Combine header fields with the same name into one
      # "header-name:comma-separated-value-list" pair as prescribed by
      # RFC 2616, section 4.2, without any white-space between
      # values. For example, the two metadata headers
      # 'x-amz-meta-username: fred' and 'x-amz-meta-username: barney'
      # would be combined into the single header 'x-amz-meta-username:
      # fred,barney'.
      groupped_headers = headers.group_by { |i| i.first }
      #=> {"a"=>[["a", 1], ["a", 2]], "b"=>[["b", 3]], "c"=>[["c", 0]]}
      combined_headers = groupped_headers.map do |key, value|
        values = value.map { |e| e.last }
        [key, values.join(",")]
      end
      #=> [["a", "1,2"], ["b", "3"], ["c", "0"]]

      # 4. "Un-fold" long headers that span multiple lines (as allowed
      # by RFC 2616, section 4.2) by replacing the folding white-space
      # (including new-line) by a single space.
      unfolded_headers = combined_headers.map do |header|
        key = header.first
        value = header.last
        value.gsub!(/\s+/, " ")
        [key, value]
      end

      # 5. Trim any white-space around the colon in the header. For
      # example, the header 'x-amz-meta-username: fred,barney' would
      # become 'x-amz-meta-username:fred,barney'
      joined_headers = unfolded_headers.map do |header|
        key = header.first.strip
        value = headers.last.strip
        "#{key}:#{value}"
      end

      # 6. Finally, append a new-line (U+000A) to each canonicalized
      # header in the resulting list. Construct the
      # CanonicalizedResource element by concatenating all headers in
      # this list into a single string.
      joined_headers.join("\n")
    end
  end
end

