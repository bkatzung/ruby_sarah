require 'minitest/autorun'
require 'sarah'

class TestSarah_08 < MiniTest::Unit::TestCase

    def setup
	@s1 = Sarah[1, 3, 4, 5, 'a', 'c', 'd', 'e', 20 => 'x', 21 => 'y']
	@a1 = [1, 3, 4, 5, 'a', 'c', 'd', 'e', 'x', 'y']
	@s2 = Sarah[1, 2, 3, 5, 'a', 'b', 'c', 'e', 20 => 'x', 22 => 'z']
	@a2 = [1, 2, 3, 5, 'a', 'b', 'c', 'e', 'x', 'z']

	@s3 = Sarah[ :a => ?a, :b => ?b, :c => ?c, :d => ?d, :x => 1 ]
	@s4 = Sarah[ :b => ?b, :d => ?d, :e => ?e, :x => 2 ]
    end

    def test_inter
	assert_equal((@a1 & @a2), (@s1 & @s2).values, 'Sarah ary intersection')
	assert_equal({ :b => ?b, :d => ?d }, (@s3 & @s4).to_h,
	  'Sarah rnd intersection')
    end

    def test_union
	assert_equal((@a1 | @a2), (@s1 | @s2).values, 'Sarah ary union')
	assert_equal({ :a => ?a, :b => ?b, :c => ?c, :d => ?d,
	  :e => ?e, :x => 2}, (@s3 | @s4).to_h, 'Sarah rnd union')
    end

    def test_minus
	assert_equal((@a1 - @a2), (@s1 - @s2).values, 'Sarah ary difference')
	assert_equal({ :a => ?a, :c => ?c, :x => 1 }, (@s3 - @s4).to_h,
	  'Sarah rnd difference')
    end

end

# END
