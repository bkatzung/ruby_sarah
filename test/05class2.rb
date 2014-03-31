require 'minitest/autorun'
require 'sarah'

# Class methods since 2.0.0

class TestSarah_05 < MiniTest::Unit::TestCase

    def test_cmethod
	[ :[], :new, :try_convert
	].each { |method| assert_respond_to Sarah, method }
    end

    def test_copy
	s1 = Sarah[ 1, 2, 5 => 'five', :ten => 10 ]
	s1.default = false
	s1.negative_mode = :actual
	s2 = Sarah.new s1

	assert_equal s1.to_a, s2.to_a, 's1.to_a == s2.to_a'
	assert_equal s1.to_h, s2.to_h, 's1.to_h == s2.to_h'
	assert_equal :actual, s2.negative_mode, ':actual mode copied'
	assert_equal false, s2.default, 'default copied'
    end

    def test_new
	assert_equal [0, 'one', 5 => 'five', :ten => 10 ],
	  Sarah[0, 'one', 5 => 'five', :ten => 10 ].to_a,
	  'Failed to create Sarah literal'

	assert_equal [0, 'one', {}],
	  Sarah.new(:from => [0, 'one']).to_a,
	  'Failed to create Sarah from array'

	assert_equal [0, 'one', 5 => 'five', :ten => 10 ],
	  Sarah.new(:from => { 0 => 0, 1 => 'one', 5 => 'five', :ten => 10 }).
	  to_a, 'Failed to create Sarah from hash'

	assert_equal [0, 'one', {}],
	  Sarah.try_convert([0, 'one']).to_a,
	  'Failed to try_convert array to Sarah'

	assert_equal [0, 'one', 5 => 'five', :ten => 10 ],
	  Sarah.try_convert({ 0 => 0, 1 => 'one', 5 => 'five', :ten => 10 }).
	  to_a, 'Failed to try_convert hash to Sarah'
    end

end

# END
