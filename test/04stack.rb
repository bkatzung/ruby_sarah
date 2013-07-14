require 'minitest/autorun'
require 'sarah'

class TestSarah_04 < MiniTest::Unit::TestCase

    def test_stack
	s = Sarah.new
	s.push 1, 2, 3
	s.unshift 4, 5, 6
	assert_equal([4, 5, 6, 1, 2, 3], s.seq, "push + unshift")
	assert_equal(4, s.shift, "shift")
	assert_equal(3, s.pop, "pop")
	assert_equal([5, 6, 1, 2], s.seq, "after shift, pop")
    end

    def test_left_shift
	s = Sarah.new
	s << 1 << 2 << 3
	assert_equal([1, 2, 3], s.seq, "<<")
    end

    def test_append
	s = Sarah.new
	s.append! [1], { :one => 1 }, [2], [3]
	s.append! [4], { :two => 2 }, [5], [6]
	assert_equal([1, 2, 3, 4, 5, 6], s.seq, "append ary")
	assert_equal({ :one => 1, :two => 2 }, s.rnd, "append hsh")
    end

    def test_insert
	s = Sarah.new
	s.insert! [1], { :one => 1 }, [2], [3]
	s.insert! [4], { :two => 2 }, [5], [6]
	assert_equal([4, 5, 6, 1, 2, 3], s.seq, "insert ary")
	assert_equal({ :one => 1, :two => 2 }, s.rnd, "insert hsh")
    end

end

# END
