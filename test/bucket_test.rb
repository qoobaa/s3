require 'test_helper'

class BucketTest < Test::Unit::TestCase
  def test_parse_name_with_vhost_name
    host, prefix = S3::Bucket.parse_name("data.synergypeople.net", "s3.amazonaws.com")
    assert_equal "data.synergypeople.net.s3.amazonaws.com", host
    assert_equal "", prefix
  end

  def test_parse_name_with_prefix_based_name
    host, prefix = S3::Bucket.parse_name("synergypeople_net", "s3.amazonaws.com")
    assert_equal "s3.amazonaws.com", host
    assert_equal "/synergypeople_net", prefix
  end
end
