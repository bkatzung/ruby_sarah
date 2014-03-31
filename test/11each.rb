require 'minitest/autorun'
require 'sarah'

class TestSarah_11 < MiniTest::Unit::TestCase

    def test_each
	s = Sarah[1, 2, 5 => 3, 6 => 4, :a => 5, :b => 6]

	h = {}
	s.each(:seq) { |k, v| h[k] = v }
	assert_equal({ 0 => 1, 1 => 2 }, h, 'each :seq')

	h.clear
	s.each(:spr) { |k, v| h[k] = v }
	assert_equal({ 5 => 3, 6 => 4 }, h, 'each :spr')

	h.clear
	s.each(:ary) { |k, v| h[k] = v }
	assert_equal({ 0 => 1, 1 => 2, 5 => 3, 6 => 4 }, h, 'each :ary')

	h.clear
	s.each(:rnd) { |k, v| h[k] = v }
	assert_equal({ :a => 5, :b => 6 }, h, 'each :rnd')

	h.clear
	s.each(:all) { |k, v| h[k] = v }
	assert_equal s.to_h, h, 'each :all'

	a = []
	s.reverse_each { |k, v| a << [k, v] }
	assert_equal [[6, 4], [5, 3], [1, 2], [0, 1]], a, 'reverse_each'
    end

    def test_pairs_at
	s = Sarah[1, 2, 5 => 3, 6 => 4, :a => 5, :b => 6]

	assert_equal s.to_h, s.pairs_at(*s.keys), 'to_h matches pairs_at(*keys)'
    end

    def test_values_at
	s = Sarah[1, 2, 5 => 3, 6 => 4, :a => 5, :b => 6]

	assert_equal s.values, s.values_at(*s.keys),
	  'values matches values_at(*keys)'
    end

end

# END
