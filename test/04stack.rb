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

    def test_append_sarah
	s1 = Sarah.new :array => [1, 2], :hash => { :three => 3 }
	s2 = Sarah.new :array => [4, 5], :hash => { :six => 6 }
	s1.append! s2
	assert_equal([1, 2, 4, 5], s1.seq, "append sarah (array)")
	assert_equal({ :three => 3, :six => 6 }, s1.rnd, "append sarah (hash)")
    end

    def test_insert
	s = Sarah.new
	s.insert! [1], { :one => 1 }, [2], [3]
	s.insert! [4], { :two => 2 }, [5], [6]
	assert_equal([4, 5, 6, 1, 2, 3], s.seq, "insert ary")
	assert_equal({ :one => 1, :two => 2 }, s.rnd, "insert hsh")
    end

    def test_insert_sarah
	s1 = Sarah.new :array => [1, 2], :hash => { :three => 3 }
	s2 = Sarah.new :array => [4, 5], :hash => { :six => 6 }
	s1.insert! s2
	assert_equal([4, 5, 1, 2], s1.seq, "insert sarah (array)")
	assert_equal({ :three => 3, :six => 6 }, s1.rnd, "insert sarah (hash)")
    end

end

# END
