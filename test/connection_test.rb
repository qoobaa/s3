require 'test_helper'

class ConnectionTest < Test::Unit::TestCase
  def setup
    @connection = S3::Connection.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @http_request = Net::HTTP.new("")
    @response_ok = Net::HTTPOK.new("1.1", "200", "OK")
    @response_not_found = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    stub(@connection).http { @http_request }
    stub(@http_request).start { @response_ok }
  end

  def test_handle_response_not_modify_response_when_ok
    assert_nothing_raised do
      response = @connection.request(
        :get,
        :host => "s3.amazonaws.com",
        :path => "/"
      )
      assert_equal @response_ok, response
    end
  end

  def test_handle_response_throws_exception_when_not_ok
    response_body = <<-EOFakeBody
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <SomeResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
      <Code>NoSuchBucket</Code>
      <Message>The specified bucket does not exist</Message>
    </SomeResult>
    EOFakeBody
    stub(@http_request).start { @response_not_found }
    stub(@response_not_found).body { response_body }

    assert_raise S3::Error::NoSuchBucket do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end
  end

  def test_handle_response_throws_standard_exception_when_not_ok
    stub(@http_request).start { @response_not_found }
    stub(@response_not_found).body { nil }
    assert_raise S3::Error::ResponseError do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end

    stub(@response_not_found).body { "" }
    assert_raise S3::Error::ResponseError do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end
  end

  def test_parse_params_empty
    expected = ""
    actual = S3::Connection.parse_params({})
    assert_equal expected, actual
  end

  def test_parse_params_only_interesting_params
    expected = ""
    actual = S3::Connection.parse_params(:param1 => "1", :maxkeys => "2")
    assert_equal expected, actual
  end

  def test_parse_params_remove_underscore
    expected = "max-keys=100"
    actual = S3::Connection.parse_params(:max_keys => 100)
    assert_equal expected, actual
  end

  def test_parse_params_with_and_without_values
    expected = "max-keys=100&prefix"
    actual = S3::Connection.parse_params(:max_keys => 100, :prefix => nil)
    assert_equal expected, actual
  end

  def test_headers_headers_empty
    expected = {}
    actual = S3::Connection.parse_headers({})
    assert_equal expected, actual
  end

  def test_parse_headers_only_interesting_headers
    expected = {}
    actual = S3::Connection.parse_headers(
      :accept => "text/*, text/html, text/html;level=1, */*",
      :accept_charset => "iso-8859-2, unicode-1-1;q=0.8"
    )
    assert_equal expected, actual
  end

  def test_parse_headers_remove_underscore
    expected = {
      "content-type" => nil,
      "x-amz-acl" => nil,
      "if-modified-since" => nil,
      "if-unmodified-since" => nil,
      "if-match" => nil,
      "if-none-match" => nil,
      "content-disposition" => nil,
      "content-encoding" => nil
    }
    actual = S3::Connection.parse_headers(
      :content_type => nil,
      :x_amz_acl => nil,
      :if_modified_since => nil,
      :if_unmodified_since => nil,
      :if_match => nil,
      :if_none_match => nil,
      :content_disposition => nil,
      :content_encoding => nil
    )
    assert_equal expected, actual
  end

  def test_parse_headers_with_values
    expected = {
      "content-type" => "text/html",
      "x-amz-acl" => "public-read",
      "if-modified-since" => "today",
      "if-unmodified-since" => "tomorrow",
      "if-match" => "1234",
      "if-none-match" => "1243",
      "content-disposition" => "inline",
      "content-encoding" => "gzip"
    }
    actual = S3::Connection.parse_headers(
      :content_type => "text/html",
      :x_amz_acl => "public-read",
      :if_modified_since => "today",
      :if_unmodified_since => "tomorrow",
      :if_match => "1234",
      :if_none_match => "1243",
      :content_disposition => "inline",
      :content_encoding => "gzip"
    )
    assert_equal expected, actual
  end

  def test_parse_headers_with_range
    expected = {
      "range" => "bytes=0-100"
    }
    actual = S3::Connection.parse_headers(
      :range => 0..100
    )
    assert_equal expected, actual
  end
end
