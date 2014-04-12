require 'minitest/autorun'
require 'sarah'

# Test changes for version 2.2.0:
# :nsq for #each and #empty?

class TestSarah_16 < MiniTest::Unit::TestCase

    def test_each
	s = Sarah[1, 2, 5 => 'five', :a => ?a]
	my_h = {}
	s.each(:nsq) { |k, v| my_h[k] = v }
	assert_equal s.to_h(:nsq), my_h, 'each :nsq matches to_h :nsq'
    end

    def test_empty
	s0 = Sarah[1, 2, 5 => 'five', :a => ?a]
	s = Sarah.new s0
	assert_equal false, s.empty?(:nsq), 'not empty? :nsq'
	s.delete_at 5
	assert_equal false, s.empty?(:nsq), 'not empty? :nsq after delete 5'
	s = Sarah.new s0
	s.delete_at :a
	assert_equal false, s.empty?(:nsq), 'not empty? :nsq after delete a'
	s.delete_at 5
	assert_equal true, s.empty?(:nsq), 'empty? :nsq after delete 5 and a'
    end

end

# END
