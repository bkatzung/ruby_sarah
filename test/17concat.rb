require 'minitest/autorun'
require 'sarah'

class TestSarah_17 < MiniTest::Unit::TestCase

    def test_append
	s1 = Sarah[1, 'two' => 2]
	s2 = Sarah[2, 'three' => 3]
	s1.append! s2
	assert_equal({ 0=>1, 1=>2, 'two'=>2, 'three'=>3 }, s1.to_h,
	  's1.append! s2')
    end

    def test_concat
	s1 = Sarah[1, 'two' => 2]
	s2 = Sarah[2, 'three' => 3]
	s1.concat s2
	assert_equal({ 0=>1, 1=>2, 'two'=>2, 'three'=>3 }, s1.to_h,
	  's1.concat s2')
    end

    def test_plus
	s1 = Sarah[1, 'two' => 2]
	s2 = Sarah[2, 'three' => 3]
	s3 = s1 + s2
	assert_equal({ 0=>1, 1=>2, 'two'=>2, 'three'=>3 }, s3.to_h, 's1+s2')
	assert_equal({ 0=>1, 'two'=>2 }, s1.to_h, 's1 unchanged')
    end

    def test_sparse
	s1 = Sarah[1, 5 => 'five']
	s2 = Sarah[2, 6 => 'six']
	s1.concat s2
	assert_equal({ 0=>1, 5=>'five', 6=>2, 7=>'six' }, s1.to_h,
	  'sparse s1.concat s2')
    end

end

# END
