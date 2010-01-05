module S3

  # Class responsible for generating signatures to requests.
  #
  # Implements algorithm defined by Amazon Web Services to sign
  # request with secret private credentials
  #
  # === See:
  # http://docs.amazonwebservices.com/AmazonS3/latest/index.html?RESTAuthentication.html

  class Signature

    # Generates signature for given parameters
    #
    # ==== Parameters:
    # +options+: a hash that contains options listed below
    #
    # ==== Options:
    # +host+: hostname
    # +request+: Net::HTTPRequest object with correct headers
    # +access_key_id+: access key id
    # +secret_access_key+: secret access key
    #
    # ==== Returns:
    # Generated signature for given hostname and request
    def self.generate(options)
      request = options[:request]
      host = options[:host]
      access_key_id = options[:access_key_id]
      secret_access_key = options[:secret_access_key]

      http_verb = request.method
      content_md5 = request["content-md5"] || ""
      content_type = request["content-type"] || ""
      date = request["x-amz-date"].nil? ? request["date"] : ""
      canonicalized_resource = canonicalized_resource(host, request)
      canonicalized_amz_headers = canonicalized_amz_headers(request)

      string_to_sign = ""
      string_to_sign << http_verb
      string_to_sign << "\n"
      string_to_sign << content_md5
      string_to_sign << "\n"
      string_to_sign << content_type
      string_to_sign << "\n"
      string_to_sign << date
      string_to_sign << "\n"
      string_to_sign << canonicalized_amz_headers
      string_to_sign << canonicalized_resource

      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)
      base64 = Base64.encode64(hmac)
      signature = base64.chomp

      "AWS #{access_key_id}:#{signature}"
    end

    # ==== Parameters:
    # +options+:: Hash of options
    #
    # ==== Options:
    # +bucket+:: the bucket in which the resource resides
    # +resource+:: the path to the resouce you want to create a teporary link to
    # +secret_access_key+:: the secret access key
    # +expires_on+:: the unix time stamp of when the resouce link will expire
    def self.generate_temporary_url_signature(options)
      bucket = options[:bucket]
      resource = options[:resource]
      secret_access_key = options[:secret_access_key]
      expires = options[:expires_on]

      string_to_sign = "GET\n\n\n#{expires}\n/#{bucket}/#{resource}";

      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)
      base64 = Base64.encode64(hmac)
      signature = base64.chomp

      CGI.escape(signature)
    end

    private

    # Helper method for extracting header fields from Net::HTTPRequest and
    # preparing them for singing in #generate method
    #
    # ==== Parameters:
    # +request+: Net::HTTPRequest object with header fields filled in
    #
    # ==== Returns:
    # String containing interesting header fields in suitable order and form
    def self.canonicalized_amz_headers(request)
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
        value = header.last.strip
        "#{key}:#{value}"
      end

      # 6. Finally, append a new-line (U+000A) to each canonicalized
      # header in the resulting list. Construct the
      # CanonicalizedResource element by concatenating all headers in
      # this list into a single string.
      joined_headers << "" unless joined_headers.empty?
      joined_headers.join("\n")
    end

    # Helper methods for extracting caninocalized resource address
    #
    # ==== Parameters:
    # +host+: hostname
    # +request+: Net::HTTPRequest object with headers filealds filled in
    #
    # ==== Returns:
    # String containing extracted canonicalized resource
    def self.canonicalized_resource(host, request)
      # 1. Start with the empty string ("").
      string = ""

      # 2. If the request specifies a bucket using the HTTP Host
      # header (virtual hosted-style), append the bucket name preceded
      # by a "/" (e.g., "/bucketname"). For path-style requests and
      # requests that don't address a bucket, do nothing. For more
      # information on virtual hosted-style requests, see Virtual
      # Hosting of Buckets.
      bucket_name = host.sub(/\.?s3\.amazonaws\.com\Z/, "")
      string << "/#{bucket_name}" unless bucket_name.empty?

      # 3. Append the path part of the un-decoded HTTP Request-URI,
      # up-to but not including the query string.
      uri = URI.parse(request.path)
      string << uri.path

      # 4. If the request addresses a sub-resource, like ?location,
      # ?acl, or ?torrent, append the sub-resource including question
      # mark.
      string << "?#{$1}" if uri.query =~ /&?(acl|torrent|logging|location)(?:&|=|\Z)/
      string
    end
  end
end
