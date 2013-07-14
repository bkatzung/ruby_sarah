require 'minitest/autorun'
require 'sarah'

class TestSarah_03 < MiniTest::Unit::TestCase

    def setup
	@s = Sarah.new(:array => [1, 2], :hash => { :a => 3, :b => 4 })
    end

    def test_clear
	assert_equal(4, @s.size, "has size 4 before clear")
	@s.clear
	assert_equal(0, @s.size, "has size 0 after clear")
    end

    def test_has_key
	assert_equal(true, @s.has_key?(0), "has key 0")
	assert_equal(true, @s.has_key?(-1), "has key -1")
	assert_equal(true, @s.has_key?(:a), "has key :a")
	assert_equal(false, @s.has_key?(2), "has no key 2")
	assert_equal(false, @s.has_key?(:c), "has no key :c")
    end

    def test_get_set
	assert_equal(1, @s[0], "get key 0 value 1")
	assert_equal(2, @s[1], "get key 1 value 2")
	assert_equal(3, @s[:a], "get key :a value 3")
	assert_equal(4, @s[:b], "get key :b value 4")

	@s[2] = 5
	@s[:c] = 6
	assert_equal(5, @s[2], "set/get key 2 value 5")
	assert_equal(6, @s[:c], "set/get key :c value 6")
    end

    def test_default
	assert_equal(1, @s[0], "confirm key 0 value 1")
	assert_equal(nil, @s[2], "default default nil")

	s = Sarah.new(:array => [0], :default => false)
	assert_equal(0, s[0], "confirm key 0 value 0")
	assert_equal(false, s[1], "explicit default false")

	s = Sarah.new(:array => [0]) { |s, key| key }
	assert_equal(0, s[0], "confirm key 0 value 0")
	assert_equal(1, s[1], "block default 1")
	assert_equal(2, s[2], "block default 2")
    end

    def test_fetch
	assert_equal(1, @s.fetch(0), "fetch key 0 value 0")
	assert_raises(KeyError, "fetch with exception") { @s.fetch 2 }
	assert_equal(false, @s.fetch(2, false), "fetch with default")
	assert_equal(2, @s.fetch(2) { |key| key }, "fetch with block")
    end

end

# END
