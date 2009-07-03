require 'test_helper'

class BucketTest < Test::Unit::TestCase
  def setup
    @bucket_vhost = S3::Bucket.new(nil, "data-bucket")
    @bucket_path = S3::Bucket.new(nil, "data_bucket")
  end

  def test_name_valid
    assert_raise ArgumentError do S3::Bucket.new(nil, "") end # should not be valid with empty name
    assert_raise ArgumentError do S3::Bucket.new(nil, "10.0.0.1") end # should not be valid with IP as name
    assert_raise ArgumentError do S3::Bucket.new(nil, "as") end # should not be valid with name shorter than 3 characters
    assert_raise ArgumentError do S3::Bucket.new(nil, "a"*256) end # should not be valid with name longer than 255 characters
    assert_raise ArgumentError do S3::Bucket.new(nil, ".asdf") end # should not allow special characters as first character
    assert_raise ArgumentError do S3::Bucket.new(nil, "-asdf") end # should not allow special characters as first character
    assert_raise ArgumentError do S3::Bucket.new(nil, "_asdf") end # should not allow special characters as first character

    assert_nothing_raised do
      S3::Bucket.new(nil, "a-a-")
      S3::Bucket.new(nil, "a.a.")
      S3::Bucket.new(nil, "a_a_")
    end
  end

  def test_path_prefix
    expected = ""
    actual = @bucket_vhost.path_prefix
    assert_equal expected, actual

    expected = "data_bucket/"
    actual = @bucket_path.path_prefix
    assert_equal expected, actual
  end

  def test_host
    expected = "data-bucket.s3.amazonaws.com"
    actual = @bucket_vhost.host
    assert_equal expected, actual

    expected = "s3.amazonaws.com"
    actual = @bucket_path.host
    assert_equal expected, actual
  end

  def test_vhost
    assert @bucket_vhost.vhost?
    assert ! @bucket_path.vhost?
  end

  def test_exists
    mock(@bucket_vhost).retrieve { @bucket_vhost }
    assert @bucket_vhost.exists?

    mock(@bucket_vhost).retrieve { raise S3::Error::NoSuchBucket.new(nil, nil) }
    assert ! @bucket_vhost.exists?
  end

end
