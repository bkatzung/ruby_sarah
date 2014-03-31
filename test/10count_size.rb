require 'minitest/autorun'
require 'sarah'

class TestSarah_10 < MiniTest::Unit::TestCase

    def test_count
	s0 = Sarah[ 1, 3, 5 => 1, 6 => 3, :a => 3, :b => 5 ]

	assert_equal 2, s0.count(:ary, 1), 'count :ary, 1'
	assert_equal 4, s0.count(:ary) { |i| i.odd? }, 'count :ary, odd'
	assert_equal 1, s0.count(:rnd, 3), 'count :rnd, 3'
	assert_equal 2, s0.count(:rnd) { |i| i.odd? }, 'count :rnd, odd'
	assert_equal 3, s0.count(:all, 3), 'count :all, 3'
	assert_equal 6, s0.count(:all) { |i| i.odd? }, 'count :all, odd'
	assert_equal 6, s0.count { |i| i.odd? }, 'count odd'
    end

    def test_size
	s = Sarah[1, 2, 3, 4, 7 => 5, 8 => 6, :ix => 7]

	assert_equal 4, s.size(:seq), 'size :seq'
	assert_equal 2, s.size(:spr), 'size :spr'
	assert_equal 6, s.size(:ary), 'size :ary'
	assert_equal 1, s.size(:rnd), 'size :rnd'
	assert_equal 7, s.size(:all), 'size :all'
	assert_equal 7, s.size, 'size'

	s.unset_value 3
	assert_equal 2, s.size(:seq), 'size :seq after unset'
	assert_equal 3, s.size(:spr), 'size :spr after unset'
	assert_equal 5, s.size(:ary), 'size :ary after unset'
    end

end

# END
