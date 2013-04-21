$LOAD_PATH << '../lib/sarah'

require 'minitest/autorun'
require 'sarah'

class TestSarah < MiniTest::Unit::TestCase

    def test_new_array
	s = Sarah.new(:array => [1, 2])
	assert_equal([1, 2], s.seq, "new array seq [...]")
	assert_equal({}, s.rnd, "new array rnd {}")
	assert_equal(2, s.seq_size, "new array seq_size")
	assert_equal(0, s.rnd_size, "new array rnd_size")
    end

    def test_new_hash
	s = Sarah.new(:hash => { :one => 1, :two => 2 })
	assert_equal([], s.seq, "new hash seq []")
	assert_equal({ :one => 1, :two => 2 }, s.rnd, "new hash rnd {...}")
	assert_equal(0, s.seq_size, "new hash seq_size")
	assert_equal(2, s.rnd_size, "new hash rnd_size")
    end

    def test_new_mixed
	s = Sarah.new(:array => [1, 2], :hash => { :one => 1, :two => 2 })
	assert_equal([1, 2], s.seq, "new mixed seq [...]")
	assert_equal({ :one => 1, :two => 2 }, s.rnd, "new mixed rnd {...}")
	assert_equal(2, s.seq_size, "new mixed seq_size")
	assert_equal(2, s.rnd_size, "new mixed rnd_size")
    end

    def test_new_consecutive
	s = Sarah.new(:array => [0, 1], :hash => { 2 => :two, 3 => :three })
	assert_equal([0, 1, :two, :three], s.seq, "new consecutive [...]")
	assert_equal(4, s.seq_size, "new consecutive seq_size")
	assert_equal(0, s.rnd_size, "new consecutive rnd_size")
    end

end

# END
