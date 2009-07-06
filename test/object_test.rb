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
end
