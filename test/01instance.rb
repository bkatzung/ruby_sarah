require 'minitest/autorun'
require 'sarah'

class TestSarah_01 < MiniTest::Unit::TestCase

    def setup
	@s = Sarah.new
    end

    def test_imethods_accessors
	[
	  :default, :default=, :default_proc, :default_proc=
	].each { |method| assert_respond_to @s, method }
    end

    def test_imethods_user_api
	[
	  :clear, :has_key?, :[], :[]=, :fetch,
	  :shift, :pop, :each, :each_pair, :each_index,
	  :set, :set_pairs, :set_kv, :append!, :merge!,
	  :unshift, :push, :delete_key,
	  :size, :seq_size, :rnd_size, :length, :seq_length, :rnd_length,
	  :seq, :rnd, :keys, :seq_keys, :rnd_keys,
	  :values, :seq_values, :rnd_values,
	  :slice, :slice!, :seq_slice, :seq_slice!
	].each { |method| assert_respond_to @s, method }
    end

end

# END
