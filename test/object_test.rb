require 'test_helper'

class ObjectTest < Test::Unit::TestCase
  def setup
  end

  def test_initilalize
    assert_raise ArgumentError do S3::Object.new(nil, "") end # should not allow empty key
    assert_raise ArgumentError do S3::Object.new(nil, "//") end # should not allow key with double slash
  end

  def test_full_key
  end

  def test_url
  end

  def test_cname_url
  end
end
