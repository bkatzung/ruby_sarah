require 'minitest/autorun'
require 'sarah'

class TestSarah_12 < MiniTest::Unit::TestCase

    def test_has_key
	s = Sarah[1, 2, 5 => 3, 6 => 4, :vii => 5, 'eight' => 6]

	assert_equal true, s.has_key?(0), 'has key 0'
	assert_equal false, s.has_key?(2), 'has key 2'
	assert_equal true, s.has_key?(5), 'has key 5'
	assert_equal false, s.has_key?(7), 'has key 7'
	assert_equal true, s.has_key?(:vii), 'has key :vii'
	assert_equal true, s.has_key?('eight'), "has key 'eight'"
    end

    def test_has_value
	s = Sarah[1, 2, 5 => 3, 6 => 4, :vii => 5, 'eight' => 6]

	assert_equal false, s.has_value?(0), 'has value 0'
	assert_equal true, s.has_value?(1), 'has value 1'
	assert_equal true, s.has_value?(3), 'has value 3'
	assert_equal true, s.has_value?(5), 'has value 5'
	assert_equal false, s.has_value?(7), 'has value 7'
    end

    def test_index
	s = Sarah[1, 2, 3, 3, 5 => 1, 6 => 2, :vii => 3, 'eight' => 4]

	assert_equal 1, s.index(2), 'index 2'
	assert_equal 2, s.index(3), 'index 3'
	assert_equal(2, s.index { |v| v == 3 }, 'index { v == 3 }')
	assert_equal nil, s.index(4), 'index 4'
	assert_equal nil, s.index(5), 'index 5'
	assert_equal 5, s.rindex(1), 'rindex 1'
	assert_equal 3, s.rindex(3), 'rindex 3'
	assert_equal(3, s.rindex { |v| v == 3 }, 'rindex { v == 3 }')
    end

    def test_key
	s = Sarah[1, 2, 3, 3, 5 => 1, 6 => 2, :vii => 4, 'eight' => 5]

	assert_equal 0, s.key(1), 'key 1'
	assert_equal 1, s.key(2), 'key 2'
	assert_equal 2, s.key(3), 'key 3'
	assert_equal :vii, s.key(4), 'key 4'
	assert_equal 'eight', s.key(5), 'key 5'
    end

end

# END
