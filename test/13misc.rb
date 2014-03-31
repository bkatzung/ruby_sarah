require 'minitest/autorun'
require 'sarah'

class TestSarah_13 < MiniTest::Unit::TestCase

    def test_assoc
	s = Sarah[ [ :one, 'one', 1 ], [ 'two', 'two', 2 ],
	  'three' => [ 'three', 3 ] ]

	assert_equal [ :one, 'one', 1 ], s.assoc(:one), 'assoc ary :one'
	assert_equal [ 'two', 'two', 2 ], s.assoc('two'), 'assoc ary two'
	assert_equal [ 'three', 'three', 3 ], s.assoc('three'),
	  'assoc hsh three'
    end

    def test_collect
	s0 = Sarah[ 1, 2 => 2, '4' => 4 ]

	s1 = Sarah.new(s0)
	assert_equal({ 0 => 1, 2 => 2, '4' => 4 }, s1.to_h,
	  'collect verify copy')

	s1 = Sarah.new(s0).collect!(:seq) { |v| v * 2 }
	assert_equal({ 0 => 2, 2 => 2, '4' => 4 }, s1.to_h, 'collect! :seq')

	s1 = Sarah.new(s0).collect!(:spr) { |v| v * 2 }
	assert_equal({ 0 => 1, 2 => 4, '4' => 4 }, s1.to_h, 'collect! :spr')

	s1 = Sarah.new(s0).collect!(:ary) { |v| v * 2 }
	assert_equal({ 0 => 2, 2 => 4, '4' => 4 }, s1.to_h, 'collect! :ary')

	s1 = Sarah.new(s0).collect!(:rnd) { |v| v * 2 }
	assert_equal({ 0 => 1, 2 => 2, '4' => 8 }, s1.to_h, 'collect! :rnd')

	s1 = Sarah.new(s0).collect!(:all) { |v| v * 2 }
	assert_equal({ 0 => 2, 2 => 4, '4' => 8 }, s1.to_h, 'collect! :all')

	s1 = Sarah.new(s0).collect! { |v| v * 2 }
	assert_equal({ 0 => 2, 2 => 4, '4' => 8 }, s1.to_h, 'collect!')
    end

    def test_compact
	s0 = Sarah[ nil, 1, nil, 2, 10 => nil, 12 => 12, 14 => nil, 16 => 16,
	  :a => nil, :b => ?b, :c => nil, :d => ?d ]

	s1 = Sarah.new(s0).compact!(:ary)
	assert_equal [ 1, 2, 12, 16, { :a => nil, :b => ?b,
	  :c => nil, :d => ?d } ], s1.to_a, 'compact! :ary'

	s1 = Sarah.new(s0).compact!(:rnd)
	assert_equal [ nil, 1, nil, 2, { 10 => nil, 12 => 12, 14 => nil,
	  16 => 16, :b => ?b, :d => ?d } ], s1.to_a, 'compact! :rnd'

	s1 = Sarah.new(s0).compact!(:all)
	assert_equal [ 1, 2, 12, 16, { :b => ?b, :d => ?d } ],
	  s1.to_a, 'compact! :all'

	s1 = Sarah.new(s0).compact!
	assert_equal [ 1, 2, 12, 16, { :b => ?b, :d => ?d } ],
	  s1.to_a, 'compact!'
    end

    def test_empty
	s = Sarah[0, 1, :key => 'value']

	assert_equal false, s.empty?, 'not empty'
	assert_equal true, s.empty?(:spr), 'empty :spr'
	assert_equal false, s.empty?(:seq), 'not empty :seq'
	s.unset_at 0
	assert_equal true, s.empty?(:seq), 'empty :seq'
	assert_equal false, s.empty?(:spr), 'not empty :spr'
	s.unset_at 1
	assert_equal true, s.empty?(:ary), 'empty :ary'
	s.unset_at :key
	assert_equal true, s.empty?, 'empty'
    end

    def test_first
	s = Sarah[0, 1, 3 => 4, 5 => 6, :key => 'value']

	assert_equal 0, s.first, 'first is 0'
	assert_equal [0], s.first(1), 'first 1 is [0]'
	assert_equal [0, 1], s.first(2), 'first 2 is [0, 1]'
	assert_equal [0, 1, 4, 6], s.first(4), 'first 4'
	assert_equal [0, 1, 4, 6], s.first(5), 'first 5'
    end

    def test_last
	s = Sarah[0, 1, 3 => 4, 5 => 6, :key => 'value']

	assert_equal 6, s.last, 'last is 6'
	assert_equal [6], s.last(1), 'last 1 is [6]'
	assert_equal [4, 6], s.last(2), 'last 2 is [4, 6]'
	assert_equal [0, 1, 4, 6], s.last(4), 'last 4'
	assert_equal [0, 1, 4, 6], s.last(5), 'last 5'
    end

    def test_replace
	s1 = Sarah[1, 3 => 3, :v => 5]
	s2 = Sarah[2, 4 => 4, :vi => 6]
	s1.replace s2

	assert_equal s2, s1, 's1.replace s2'
    end

    def test_reverse
	s = Sarah[1, 2, 3, 4 => 4, 6 => 5, 8 => 6]
	s.reverse!
	assert_equal [6, 5, 4, 3, 2, 1], s.values, 'reverse'
    end

    def test_rotate
	s = Sarah[1, 2, 3, 4, 5, 9 => 6]
	s.rotate! 2
	assert_equal [3, 4, 5, 6, 1, 2], s.values, 'rotate 2'
	s.rotate! -4
	assert_equal [5, 6, 1, 2, 3, 4], s.values, 'rotate -4'
    end

    def test_shuffle_sort
	s = Sarah[1, 2, 3, 4, 5, 9 => 6]
	10.times do
	    s.shuffle!
	    break if s.values != [1, 2, 3, 4, 5, 6]
	end

	if s.values == [1, 2, 3, 4, 5, 6]
	    assert false, 'failed to shuffle in 10 tries!!'
	else
	    assert_equal [1, 2, 3, 4, 5, 6], s.values.sort, 'shuffle'
	end

	assert_equal [1, 2, 3, 4, 5, 6], s.sort, 'sort'
	s.sort!
	assert_equal [1, 2, 3, 4, 5, 6], s.values, 'sort!'
    end

    def test_uniq
	s = Sarah[3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
	assert_equal [3, 1, 4, 5, 9, 2, 6], s.uniq, 'uniq'
	assert_equal [3, 1, 4, 1, 5, 9, 2, 6, 5, 3], s.values, 'unchanged'
	s.uniq!
	assert_equal [3, 1, 4, 5, 9, 2, 6], s.values, 'uniq!'
    end

    def test_zip
	s = Sarah[3, 1, 4, 1, 5]
	a = [9, 2, 6, 5, 3]
	assert_equal [[3, 9], [1, 2], [4, 6], [1, 5], [5, 3]],
	  s.zip(a), 'zip'
    end

end

# END
