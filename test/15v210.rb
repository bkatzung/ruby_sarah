require 'minitest/autorun'
require 'sarah'

# Test changes for version 2.1.0:
# Addition of :nsq (non-sequential) selector
# #seq returns a copy, not the underlying (actually from 2.0.0)
# #rnd returns spr + rnd, not underlying rnd
# #reindex

class TestSarah_15 < MiniTest::Unit::TestCase

    def test_nsq
	s = Sarah[1, 2, 5 => 'five', :a => ?a]
	assert_equal 2, s.size(:nsq), 'size :nsq'
	assert_equal [ 5, :a ], s.keys(:nsq), 'keys :nsq'
	assert_equal [ 'five', ?a ], s.values(:nsq), 'values :nsq'
	assert_equal [ { 5 => 'five', :a => ?a } ], s.to_a(:nsq), 'to_a :nsq'
	assert_equal({ 5 => 'five', :a => ?a }, s.to_h(:nsq), 'to_h :nsq')
    end

    def test_reindex
	s = Sarah[1, 2, 5 => 'five', :a => ?a]
	assert_equal [ 1, 2, { 5 => 'five' } ], s.to_a(:ary), 'before reindex'
	s.reindex
	assert_equal [ 1, 2, 'five', {} ], s.to_a(:ary), 'after reindex'
    end

    def test_rnd
	s = Sarah[1, 2, 5 => 'five', :a => ?a]
	assert_equal 2, s.rnd_size, 'rnd_size'
	assert_equal 1, s.size(:rnd), 'size :rnd'
	r = s.rnd
	assert_equal({ 5 => 'five', :a => ?a }, r, 'rnd returns to_h :nsq')
	r[5], r[:a] = 'six', ?b
	assert r != s.rnd, "rnd changes don't affect original"
    end

    def test_seq
	s = Sarah[1, 2, 5 => 5, :a => :a]
	seq = s.seq
	seq[0], seq[1] = 3, 4
	assert seq != s.seq, "seq changes don't affect original"
    end

end

# END
