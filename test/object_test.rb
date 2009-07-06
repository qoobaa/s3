# encoding: utf-8
require 'test_helper'

class ObjectTest < Test::Unit::TestCase
  def setup
  end

  def test_initilalize
    assert_raise ArgumentError do S3::Object.new(nil, "") end # should not allow empty key
    assert_raise ArgumentError do S3::Object.new(nil, "//") end # should not allow key with double slash

    assert_nothing_raised do
      S3::Object.new(nil, "Lena.png")
      S3::Object.new(nil, "Lena playboy.png")
      S3::Object.new(nil, "Lena Söderberg.png")
      S3::Object.new(nil, "/images/pictures/test images/Lena not full.png")
    end
  end

  def test_full_key
    bucket = S3::Bucket.new(nil, "images")
    object = S3::Object.new(bucket, "Lena.png")

    expected = "images/Lena.png"
    actual = object.full_key
    assert_equal expected, actual
  end

  def test_url
    service = S3::Service.new(
      :access_key_id => "1234",
      :secret_access_key => "1337"
    )
    bucket1 = S3::Bucket.new(service, "images")

    object11 = S3::Object.new(bucket1, "Lena.png")
    expected = "http://images.s3.amazonaws.com/Lena.png"
    actual = object11.url
    assert_equal expected, actual

    object12 = S3::Object.new(bucket1, "Lena Söderberg.png")
    expected = "http://images.s3.amazonaws.com/Lena%20S%C3%B6derberg.png"
    actual = object12.url
    assert_equal expected, actual

    bucket2 = S3::Bucket.new(service, "images_new")

    object21 = S3::Object.new(bucket2, "Lena.png")
    expected = "http://s3.amazonaws.com/images_new/Lena.png"
    actual = object21.url
    assert_equal expected, actual
  end

  def test_cname_url
    service = S3::Service.new(
      :access_key_id => "1234",
      :secret_access_key => "1337"
    )
    bucket1 = S3::Bucket.new(service, "images.example.com")

    object11 = S3::Object.new(bucket1, "Lena.png")
    expected = "http://images.example.com/Lena.png"
    actual = object11.cname_url
    assert_equal expected, actual

    object12 = S3::Object.new(bucket1, "Lena Söderberg.png")
    expected = "http://images.example.com/Lena%20S%C3%B6derberg.png"
    actual = object12.cname_url
    assert_equal expected, actual

    bucket2 = S3::Bucket.new(service, "images_new")

    object21 = S3::Object.new(bucket2, "Lena.png")
    expected = nil
    actual = object21.cname_url
    assert_equal expected, actual
  end

  def test_destroy
    object = S3::Object.new(nil, "Lena.png")
    mock(object).object_request(:delete) {}

    assert object.destroy
  end

  def test_save
    object = S3::Object.new(nil, "Lena.png")
    object.content = "test"

    @response = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@response).body { "test".force_encoding(Encoding::BINARY) }
    @response["etag"] = ""
    @response["content-type"] = "image/png"
    @response["content-disposition"] = "inline"
    @response["content-encoding"] = nil
    @response["last-modified"] = Time.now.httpdate
    @response["content-length"] = 20

    mock(object).object_request(:put, {:body=>"test", :headers=>{:x_amz_acl=>"public-read", :content_type=>"application/octet-stream"}}) { @response }

    assert object.save
  end

  def test_content_and_parse_headers
    object = S3::Object.new(nil, "Lena.png")
    @response = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@response).body { "\x89PNG\x0d\x1a\x00\x00\x00\x0dIHDR\x00\x00\x00\x96\x00\x00".force_encoding(Encoding::BINARY) }
    @response["etag"] = ""
    @response["content-type"] = "image/png"
    @response["content-disposition"] = "inline"
    @response["content-encoding"] = nil
    @response["last-modified"] = Time.now.httpdate
    @response["content-length"] = 20

    mock(object).object_request(:get) { @response }

    expected = /\x89PNG/n
    actual = object.content
    assert_match expected, actual
    assert_equal "image/png", object.content_type

    stub(object).object_request(:get) { flunk "should not use connection" }

    assert object.content

    mock(object).object_request(:get) { @response }
    assert object.content(true)
  end

  def test_retrieve
    object = S3::Object.new(nil, "Lena.png")
    @response = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@response).body { "\x89PNG\x0d\x1a\x00\x00\x00\x0dIHDR\x00\x00\x00\x96\x00\x00".force_encoding(Encoding::BINARY) }
    @response["etag"] = ""
    @response["content-type"] = "image/png"
    @response["content-disposition"] = "inline"
    @response["content-encoding"] = nil
    @response["last-modified"] = Time.now.httpdate
    @response["content-length"] = 20

    mock(object).object_request(:get, :headers=>{:range=>0..0}) { @response }

    assert object.retrieve
  end

  def test_exists
    object_ex = S3::Object.new(nil, "Lena.png")
    mock(object_ex).retrieve { true }

    assert object_ex.exists?

    object_nonex = S3::Object.new(nil, "Carmen.png")
    mock(object_nonex).retrieve { raise S3::Error::NoSuchKey.new(nil, nil) }

    assert ! object_nonex.exists?
  end

end
