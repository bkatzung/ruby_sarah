require 'minitest/autorun'
require 'sarah'

class TestSarah_14 < MiniTest::Unit::TestCase

    def test_slice
	s = Sarah[1, 2, 3, 4, 5, 10 => 6, 15 => 7, 20 => 8]

	assert_equal 2, s.slice(1), 'slice 1'
	assert_equal 6, s.slice(10), 'slice 10'
	assert_equal({ 1 => 2 }, s.slice(1, 1).to_h, 'slice 1, 1')
	assert_equal({ 1 => 2, 2 => 3 }, s.slice(1, 2).to_h, 'slice 1, 2')
	assert_equal({ 4 => 5, 10 => 6 }, s.slice(4, 2).to_h, 'slice 4, 2')
	assert_equal [5, 6, 7, 8], s.slice(4, 5).values, 'slice 4, 5'
	assert_equal({ 15 => 7 }, s.slice(-6, 1).to_h, 'slice -6, 1')
	assert_equal({ 20 => 8 }, s.slice(-3, 1).to_h, 'slice -3, 1')

	assert_equal({ 4 => 5, 10 => 6, 15 => 7 }, s.slice(4..15).to_h,
	  'slice 4..15')
	assert_equal({ 4 => 5, 10 => 6 }, s.slice(4...15).to_h,
	  'slice 4...15')
    end

    def test_slice_bang
	s0 = Sarah[1, 2, 3, 4, 5, 10 => 6, 15 => 7, 20 => 8]

	s = Sarah.new s0
	assert_equal([3, 4], s.slice!(2, 2).values, 'slice! 2, 2')
	assert_equal({ 0 => 1, 1 => 2, 2 => 5, 8 => 6, 13 => 7,
	  18 => 8 }, s.to_h, 'after slice! 2, 2')

	s = Sarah.new s0
	s.slice! 4..10
	assert_equal({ 0 => 1, 1 => 2, 2 => 3, 3 => 4, 13 => 7, 18 => 8},
	  s.to_h, 'after slice! 4..10')
    end

    def test_slice_nma
	s0 = Sarah.new [1, 2, 3, 4, 5, 10 => 6, 15 => 7, 20 => 8],
	  :negative_mode => :actual

	s = Sarah.new s0
	s.slice!(2, 2)
	assert_equal({ 0 => 1, 1 => 2, 4 => 5, 10 => 6, 15 => 7,
	  20 => 8 }, s.to_h, 'after NMA slice! 2, 2')

	s = Sarah.new s0
	s.slice! 4..10
	assert_equal({ 0 => 1, 1 => 2, 2 => 3, 3 => 4, 15 => 7, 20 => 8},
	  s.to_h, 'after NMA slice! 4..10')
    end

end

# END
