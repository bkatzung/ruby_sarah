require 'minitest/autorun'
require 'sarah'

class TestSarah_09 < MiniTest::Unit::TestCase

    def test_clear
	assert_equal({}, Sarah[ ?a, :b => ?c ].clear.to_h, 'clear :all')
	assert_equal({ :b => ?c }, Sarah[ ?a, :b => ?c ].clear(:ary).to_h,
	  'clear :ary')
	assert_equal({ 0 => ?a }, Sarah[ ?a, :b => ?c ].clear(:rnd).to_h,
	  'clear :rnd')
    end

    def test_delete_at
	s = Sarah[ 0, 1, 2, 5 => 5, 7 => 7, 9 => 9,
	  :a => ?a, :b => ?b, :c => ?c ]

	assert_equal ?b, s.delete_at(:b), 'delete_at :b'
	assert_equal 7, s.delete_at(7), 'delete_at 7'
	assert_equal 1, s.delete_at(1), 'delete_at 1'
	assert_equal [ 0, 2, 4 => 5, 7 => 9, :a => ?a, :c => ?c ], s.to_a,
	  'after delete_at x3'
    end

    def test_delete_at_nma
	s = Sarah.new([ 0, 1, 2, 5 => 5, 7 => 7, 9 => 9,
	  :a => ?a, :b => ?b, :c => ?c ], :negative_mode => :actual)

	assert_equal ?b, s.delete_at(:b), 'NMA delete_at :b'
	assert_equal 7, s.delete_at(7), 'NMA delete_at 7'
	assert_equal 1, s.delete_at(1), 'NMA delete_at 1'
	assert_equal [ 0, 2 => 2, 5 => 5, 9 => 9, :a => ?a, :c => ?c ], s.to_a,
	  'after NMA delete_at x3'
    end

    def test_delete_if
	s = Sarah[1, 2, 3, 5 => 1, 6 => 2, 7 => 3, :a => 1, :b => 2, :c => 3]

	s.delete_if(:ary) { |v, k| v == 1 }
	assert_equal [2, 3, 4 => 2, 5 => 3, :a => 1, :b => 2, :c => 3 ],
	  s.to_a, 'delete_if :ary == 1'

	s.delete_if(:rnd) { |v, k| v == 2 }
	assert_equal [2, 3, 4 => 2, 5 => 3, :a => 1, :c => 3 ],
	  s.to_a, 'delete_if :rnd == 2'

	s.delete_if { |v, k| v == 3 }
	assert_equal [2, 3 => 2, :a => 1 ], s.to_a, 'delete_if == 3'
    end

    def test_delete_val
	s = Sarah[1, 2, 3, 4, 6=>1, 7=>2, 8=>3, 9=>4, :a=>2, :b=>3 ]
	s.delete_value 2, :rnd
	assert_equal [1,2,3,4,1,2,3,4,3], s.values, 'delete_value 2, :rnd'
	s.delete_value 1, :ary
	assert_equal [2,3,4,2,3,4,3], s.values, 'delete_value 1, :ary'
	s.delete_value 3
	assert_equal [2,4,2,4], s.values, 'delete_value 3'
    end

    def test_pop
	s = Sarah[ 0, 5 => 1, 7 => 2, 9 => 3, :a => ?a]
	a = s.pop 2
	assert_equal [ 2, 3 ], a, 'spr pop 2 ressult'
	a = s.pop 2
	assert_equal [ 0, 1 ], a, 'seq/spr pop 2 result'
	assert_equal [ :a => ?a ], s.to_a, 'sarah after popping'
    end

    def test_shift
	s = Sarah[ 0, 1, 2, 5 => 5, 7 => 7, 9 => 9,
	  :a => ?a, :b => ?b, :c => ?c ]

	v = s.shift
	assert_equal 0, v, 'seq shift result'
	assert_equal [ 1, 2, 4 => 5, 6 => 7, 8 => 9, :a => ?a, :b => ?b,
	  :c => ?c ], s.to_a, 'sarah after shift'

	a = s.shift 2
	assert_equal [ 1, 2 ], a, 'seq shift 2 result'
	assert_equal [ 2 => 5, 4 => 7, 6 => 9, :a => ?a, :b => ?b,
	  :c => ?c ], s.to_a, 'sarah after shift 2'

	s = Sarah[ 0, 5 => 1, 7 => 2, 9 => 3, :a => ?a]
	a = s.shift 2
	assert_equal [ 0, 1 ], a, 'seq/spr shift 2 result'
	a = s.shift 2
	assert_equal [ 2, 3 ], a, 'spr shift 2 ressult'
	assert_equal [ :a => ?a ], s.to_a, 'sarah after shifting'
    end

    def test_unset_at
	s = Sarah[ 0, 1, 2, 5 => 5, 7 => 7, 9 => 9,
	  :a => ?a, :b => ?b, :c => ?c ]

	assert_equal ?b, s.unset_at(:b), 'unset_at :b'
	assert_equal 7, s.unset_at(7), 'unset_at 7'
	assert_equal 1, s.unset_at(1), 'unset_at 1'
	assert_equal [ 0, 2 => 2, 5 => 5, 9 => 9, :a => ?a, :c => ?c ], s.to_a,
	  'after unset_at x3'
    end

    def test_unset_if
	s = Sarah[1, 2, 3, 5 => 1, 6 => 2, 7 => 3, :a => 1, :b => 2, :c => 3]

	s.unset_if(:ary) { |v, k| v == 1 }
	assert_equal [1 => 2, 2 => 3, 6 => 2, 7 => 3,
	  :a => 1, :b => 2, :c => 3 ], s.to_a, 'unset_if :ary == 1'

	s.unset_if(:rnd) { |v, k| v == 2 }
	assert_equal [1 => 2, 2 => 3, 6 => 2, 7 => 3, :a => 1, :c => 3 ],
	  s.to_a, 'unset_if :rnd == 2'

	s.unset_if { |v, k| v == 3 }
	assert_equal [1 => 2, 6 => 2, :a => 1 ], s.to_a, 'unset_if == 3'
    end

    def test_unset_value
	s = Sarah[1, 2, 3, 4, 6=>1, 7=>2, 8=>3, 9=>4, :a=>2, :b=>3 ]

	s.unset_value 2, :rnd
	assert_equal [1, 2, 3, 4, 6 => 1, 7 => 2, 8 => 3, 9 => 4, :b => 3],
	  s.to_a, 'unset_value 2, :rnd'

	s.unset_value 1, :ary
	assert_equal [1 => 2, 2 => 3, 3 => 4, 7 => 2, 8 => 3, 9 => 4,
	  :b => 3], s.to_a, 'unset_value 1, :ary'

	s.unset_value 3
	assert_equal [1 => 2, 3 => 4, 7 => 2, 9 => 4], s.to_a, 'unset_value 3'
    end

end

# END
