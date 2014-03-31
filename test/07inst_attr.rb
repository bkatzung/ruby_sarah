require 'minitest/autorun'
require 'sarah'

class TestSarah_07 < MiniTest::Unit::TestCase

    def setup; @s = Sarah.new; end

    def test_defaults
	@s.default = true
	assert_equal true, @s.default, 'Set default to true'
	@s.default = false
	assert_equal false, @s.default, 'Change default to false'

	begin
	    @s.default_proc = Proc.new { |s, k| true }
	rescue
	    assert false, 'Failed to set valid default_proc'
	else
	    assert true, 'Succeeded in setting valid default_proc'
	    assert_kind_of Proc, @s.default_proc, 'Default_proc is a Proc'
	end

	begin
	    @s.default_proc = nil
	rescue
	    assert false, 'Failed to set nil default_proc'
	else
	    assert_equal nil, @s.default_proc,
	      'Succeeded in setting nil default_proc'
	end

	begin
	    @s.default_proc = true
	rescue TypeError
	    assert true, 'Got TypeError for invalid default_proc'
	rescue
	    assert false, 'Got incorrect exception for invalid default_proc'
	else
	    assert false, 'No exception raised for invalid default_proc'
	end
    end

    def test_neg_mode
	@s.negative_mode = :ignore
	@s.set 1, 2

	assert_equal [1, 2], @s.values, 'Two values are correct'
	assert_equal [0, 1], @s.keys, 'Two keys are correct'
	assert_equal nil, @s[2], 'Key too big returns nil'
	assert_equal nil, @s[-3], 'Ignore key too small returns nil'

	@s.negative_mode = :error
	begin
	    value = @s[-3]
	rescue IndexError
	    assert true, 'Error key too small raises IndexError'
	rescue
	    assert false, 'Error key too small raises incorrect exception'
	else
	    assert false, 'Error key too small does not raise an exception'
	end

	@s.negative_mode = :actual
	assert_equal nil, @s[-3], 'Negative key before set returns nil'
	@s[-3] = '-3'
	assert_equal '-3', @s[-3], 'Negative key after set is OK'

	@s.negative_mode = :ignore
	assert_equal :actual, @s.negative_mode,
	  'Neg mode :ignore with negative key is ignored'

	@s.negative_mode = :error
	assert_equal :actual, @s.negative_mode,
	  'Neg mode :error with negative key is ignored'

	@s.shift
	@s.negative_mode = :ignore
	assert_equal :ignore, @s.negative_mode,
	  'Neg mode :ignore after neg key removed is accepted'
    end

end

# END
