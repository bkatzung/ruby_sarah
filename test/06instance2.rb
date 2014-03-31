require 'minitest/autorun'
require 'sarah'

# Instance methods since 2.0,0

class TestSarah_06 < MiniTest::Unit::TestCase

    def setup
	@s = Sarah.new
    end

    def test_imethods_accessors
	[
	  :default, :default=, :default_proc, :default_proc=,
	  :negative_mode, :negative_mode=
	].each { |method| assert_respond_to @s, method }
    end

    def test_imethods_user_api
	[
	  :&, :|, :+, :concat, :-, :<<, :push, :==, :eql?,
	  :[], :at, :[]=, :store, :append!, :assoc,
	  :clear, :collect!, :map!, :compact!, :count,
	  :delete_at, :delete_key, :delete_if, :delete_value,
	  :each, :each_index, :each_key, :each_pair, :empty?,
	  :fetch, :find_index, :index, :first, :flatten!,
	  :has_key?, :key?, :member?, :has_value?, :include?, :value?,
	  :insert!, :inspect, :to_s, :join, :key, :keys,
	  :last, :length, :size, :merge!, :update, :new_similar,
	  :pairs_at, :pop, :rehash, :replace, :reverse!, :reverse_each,
	  :rindex, :rotate!, :sample, :select, :set, :set_kv, :set_pairs,
	  :shift, :shuffle, :shuffle!, :slice, :slice!, :sort, :sort!,
	  :to_a, :to_h, :uniq, :uniq!, :unset_at, :unset_key,
	  :unset_if, :unset_value, :unshift,
	  :values, :values_at, :zip
	].each { |method| assert_respond_to @s, method }
    end

end

# END
