# Sarah is a hybrid sequential array, sparse array, and random-access hash
# implementing alternate semantics for Ruby arrays.
#
# By default, negative indexes are relative to the end of the array (just
# like a regular Ruby Array), but they can be configured to be distinct,
# actual indexes instead.
#
# Sarahs can also be used to implement (pure Ruby) sparse matrices,
# especially when used in conjunction with the Sarah::XK module (gem
# sarah-xk), an XKeys extension for Sarah.
#
# = Background
#
# Standard Ruby lets you create an array literal like:
#
#  a = [ 1, 2, 5 => :five, :six => 'hello' ]
#
# which is a short-cut for an array with an embedded hash:
#
#  a = [ 1, 2, { 5 => :five, :six => 'hello' } }
#
#  Initially:             After v = a.shift:
#
#  a[0] = a[-3] = 1       v = 1
#  a[1] = a[-2] = 2       a[0] = a[-2] = 2
#  a[2] = a[-1] = a hash  a[1] = a[-1] = a hash
#  a[3][5] = :five        a[2][5] = :five
#  a[3][:six] = 'hello'   a[2][:six] = 'hello'
#
# In contrast, using a Sarah looks like this:
#
#  s = Sarah[ 1, 2, 5 => :five, :six => 'hello' ]
#
#  Initially:             After v = s.shift:
#
#  s[0] = s[-6] = 1       v = 1
#  s[1] = s[-5] = 2       s[0] = s[-5] = 2
#  s[5] = s[-1] = :five   s[4] = s[-1] = :five
#  s[:six] = 'hello'      s[:six] = 'hello'
#
# = Internal Structure
#
# As of version 2.0.0, there are three major data structures internally:
# * "seq" - an array of sequentially-indexed values beginning at index 0
#   (except when negative actual keys are present; see {#negative_mode=}
#   :actual)
# * "spr" - a hash representing a sparse array of all other
#   numerically-indexed values
# * "rnd" - a "random access" hash of all non-numerically keyed values
#
# The sequential and sparse parts are collectively referred to as "ary".
# All three parts together are collectively referred to as "all".
#
# Some methods allow you to direct their action to all or specific parts
# of the structure by specifying a corrsponding symbol, :seq, :spr, :ary,
# :rnd, or :all.
#
# @author Brian Katzung (briank@kappacs.com), Kappa Computer Solutions, LLC
# @copyright 2013-2014 Brian Katzung and Kappa Computer Solutions, LLC
# @license MIT License
# @version 2.0.0

class Sarah

    VERSION = "2.0.0"

    # Private attributes:
    # seq [Array] An array of (zero-origin) sequential values.
    # spr [Hash] A hash of (typically sparse) integer-keyed values. If
    #  there are any negatively-keyed values (in :actual negative mode),
    #  this hash contains all of the numerically-indexed values.
    # rnd [Hash] A hash of non-numerically-keyed values.
    # ary_first [Integer] The first integer array index.
    # ary_next [Integer] One more than the highest integer array index.

    # @!attribute default
    # The default value to return for missing keys and for pop or shift
    # on an empty array.
    attr_accessor :default

    # @!attribute default_proc
    # A proc to call to return a default value for missing keys and for
    # pop or shift on an empty array. The proc is passed the Sarah
    # and the missing key (or nil for pop and shift).
    # @return [Proc|nil]
    attr :default_proc

    # @!attribute [r] negative_mode
    # @return [:actual|:error|:ignore]
    # How negative indexes/keys are handled. Possible values are
    # :actual, :error, and :ignore. See {#negative_mode=}.
    attr_reader :negative_mode

    # ##### Class Methods #####

    # Instantiate a "Sarah literal".
    #
    #  s = Sarah[pos1, ..., posN, key1 => val1, ..., keyN => valN]
    #
    #  s = Sarah['sequen', 'tial', 5 => 'sparse', :key => 'random']
    #
    # @return [Sarah]
    # @since 2.0.0
    def self.[] (*args); new.set *args; end

    # Try to convert the passed object to a Sarah.
    #
    # In the current implementation, the object must respond to #to_sarah,
    # #each_index, or #each_pair.
    #
    # @param source [Object] The object to try to convert
    # @return [Sarah|nil]
    # @since 2.0.0
    def self.try_convert (source)
	if source.respond_to? :to_sarah then source.to_sarah
	elsif source.respond_to?(:each_index) || source.respond_to?(:each_pair)
	    new :from => source
	else nil
	end
    end

    # Initialize a new instance.
    #
    # An initialization array may optionally be passed as the first
    # parameter. (Since 2.0.0)
    #
    # If passed a block, the block is called to provide default values
    # instead of using the :default option value. The block is passed the
    # hash and the requested key (or nil for a shift or pop on an empty
    # sequential array).
    #
    #  s = Sarah.new([pos1, ..., posN, key1 => val1, ..., keyN => valN],
    #    :default => default, :default_proc => Proc.new { |sarah, key| block },
    #    :array => source, :hash => source, :from => source,
    #    :negative_mode => negative_mode)
    def initialize (*args, &block)
	opts = (!args.empty? && args[-1].is_a?(Hash)) ? args.pop : {}
	clear
	@negative_mode = :error
	self.negative_mode = opts[:negative_mode]
	@default = opts[:default]
	@default_proc = block || opts[:default_proc]
	if !args.empty?
	    case args[0]
	    when Array then set *args[0]
	    when Sarah
		self.default = args[0].default
		self.default_proc = args[0].default_proc
		self.negative_mode = args[0].negative_mode
		merge! args[0]
	    end
	end
	merge! opts[:array], opts[:hash], opts[:from]
    end

    # ##### Instance Methods #####

    # Compute the intersection with another object.
    #
    # The intersection of array values is taken without regard to indexes.
    # Random-access hash values must match by key and value.
    #
    # @return [Sarah]
    # @since 2.0.0
    def & (other)
	case other
	when Array then new_similar :array => (values(:ary) & other)
	when Hash, Sarah
	    new_similar(:array => (values(:ary) & _hash_filter(other, :array).
	      values), :hash => other.select { |k, v| @rnd[k] == v })
	else raise TypeError.new('Unsupported type in Sarah#&')
	end
    end

    # Compute the union with another object.
    #
    # Changed random-access hash values for a given key overwrite the
    # original value.
    #
    # @return [Sarah]
    # @since 2.0.0
    def | (other)
	case other
	when Array then new_similar(:hash => @rnd).merge!(values(:ary) | other)
	when Hash, Sarah
	    new_similar.merge!(@rnd, _hash_filter(other, :other),
	      values(:ary) | _hash_filter(other, :array).values)
	else raise TypeError.new('Unsupported type in Sarah#|')
	end
    end

    # #* (replicate or join) is not implemented.

    # Return a new Sarah that is the concatenation of this one and
    # another object.
    #
    # (#+ alias since 2.0.0)
    def + (other)
	new_similar(:from => self).append!(other)
    end

    alias_method :concat, :+

    # Compute the array difference with another object.
    #
    # Random-access hash values are only removed when both keys and values
    # match.
    #
    # @return [Sarah]
    # @since 2.0.0
    def - (other)
	case other
	when Array then new_similar(:array => (values(:ary) - other),
	  :hash => @rnd)
	when Hash, Sarah
	    new_similar(:array => (values(:ary) -
	      other.select { |k, v| k.is_a? Integer}.values),
	      :hash => @rnd.select { |k, v| other[k] != v })
	else raise TypeError.new('Unsupported type in Sarah#-')
	end
    end

    # Push (append) sequential values.
    #
    # @param vlist [Array] A list of values to push (append).
    # @return [Sarah]
    def << (*vlist)
	if !@spr.empty?
	    # Sparse push
	    vlist.each do |value|
		self[@ary_next] = value
		@ary_next += 1
	    end
	else
	    # Sequential push
	    @seq.push *vlist
	    @ary_next = @seq.size
	end
	self
    end

    alias_method :push, :<<

    # Array comparison (#<=>) - not supported

    # Check for equality with another object.
    #
    # Compares to arrays via {#to_a} and to hashes or Sarahs via {#to_h}.
    #
    # @since 2.0.0
    def == (other)
	case other
	when Array then to_a == other
	when Hash then to_h == other
	when Sarah then to_h == other.to_h
	else false
	end
    end

    alias_method :eql?, :==

    # Get a value by sequential or random-access key. If the key does not
    # exist, the default value or initial block value is returned. If
    # called with a range or an additional length parameter, a slice is
    # returned instead.
    #
    # @param key The key for the value to be returned, or a range.
    # @param len [Integer] An optional slice length.
    # @return [Object|Array]
    def [] (key, len = nil)
	# Slice cases...
	return slice(key, len) if len
	return slice(key) if key.is_a? Range

	if key.is_a? Integer
	    # A key in the sequential array or sparse array hash?
	    catch :index_error do
		key = _adjust_key key
		return @seq[key] if key >= 0 && key < @seq.size
		return @spr[key] if @spr.has_key? key
	    end
	else
	    # A key in the random-access hash?
	    return @rnd[key] if @rnd.has_key? key
	end

	# Return the default value
	@default_proc ? @default_proc.call(self, key) : @default
    end

    alias_method :at, :[]

    # Set a value by sequential or random-access key.
    #
    # @param key The key for which the value should be set.
    # @param value The value to set for the key.
    # @return Returns the value.
    def []= (key, value)
	if key.is_a? Integer
	    # A key in the sequential array or sparse array hash...
	    catch :index_error do
		key = _adjust_key key
		if key >= 0 && key <= @seq.size && @ary_first >= 0
		    # It's in sequence
		    @seq[key] = value
		    _spr_to_seq if @spr.has_key? @seq.size
		else
		    # It's a sparse key
		    if (@seq.empty? && @spr.empty?) || key < @ary_first
			@ary_first = key
		    end
		    _seq_to_spr if key < 0 && !@seq.empty?
		    @spr[key] = value
		end
		@ary_next = key + 1 if key >= @ary_next
	    end
	else
	    # A key in the random-access hash...
	    @rnd[key] = value
	end

	value
    end

    alias_method :store, :[]=

    # Append arrays or Sarahs and merge hashes.
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to append.
    # @return [Sarah]
    def append! (*ahlist)
	ahlist.each do |ah|
	    if ah.is_a? Sarah
		push *ah.values(:ary)
		merge! ah.to_h(:rnd)
	    elsif ah.respond_to? :each_pair
		merge! ah
	    elsif ah.respond_to? :each_index
		push *ah
	    end
	end
	self
    end

    # Return the first associated array. See Array#assoc and Hash#assoc.
    # The result is always in Array#assoc format.
    #
    # @param which [:all|:ary|:seq|:spr|:rnd] Which elements to search.
    # @return [Array|nil]
    # @since 2.0.0
    def assoc (other, which = :all)
	res = nil
	case which when :all, :ary, :seq then res ||= @seq.assoc(other) end
	case which when :all, :ary, :spr
	    res ||= @spr.values_at(*@spr.keys.sort).assoc(other)
	end
	case which when :all, :rnd
	    if res.nil?
		res = @rnd.assoc(other)
		res.flatten!(1) unless res.nil?
	    end
	end
	res
    end

    # #bsearch (binary search) is not implemented.

    # Clear sequential+sparse array and/or random-access hash values.
    #
    # @param which [:all|:ary|:rnd] (since 2.0.0)
    # @return [Sarah]
    def clear (which = :all)
	case which when :all, :ary
	    @seq, @spr, @ary_first, @ary_next = [], {}, 0, 0
	end
	case which when :all, :rnd then @rnd = {} end
	self
    end

    # #collect and #collect! are not implemented, but see #ary_collect!.

    # Collect (map) in-place. The block (required) is passed the current
    # value and the index/key (in that order). The return value of the
    # block becomes the new value.
    #
    #  s.collect!(which) { |value, key| block }
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] Which data structures
    #  are mapped.
    # @return [Sarah]
    # @since 2.0.0
    def collect! (which = :all)
	case which when :all, :ary, :seq
	    @seq.each_index { |index| @seq[index] = yield @seq[index], index }
	end
	case which when :all, :ary, :spr
	    @spr.each_pair { |key, value| @spr[key] = yield value, key }
	end
	case which when :all, :rnd
	    @rnd.each_pair { |key, value| @rnd[key] = yield value, key }
	end
	self
    end

    alias_method :map!, :collect!

    # #combination is not implemented.

    # Remove nil values in place. In the case of the sequential and sparse
    # arrays, the remaining values are reindexed sequentially from 0.
    #
    # @param which [:all|:ary|:rnd] Which data structures are compacted.
    # @return [Sarah]
    def compact! (which = :all)
	case which when :all, :ary
	    @seq = values(:ary).compact
	    @spr, @ary_first, @ary_next = {}, 0, @seq.size
	end
	case which when :all, :rnd
	    @rnd.delete_if { |key, value| value.nil? }
	end
	self
    end

    # #compare_by_identity and #compare_by_identity? are not implemented.

    # Return a count of values or matching objects
    #
    #  s.count(which, value)
    #  s.count(which) { |item| block }
    #
    # @param which [:all|:ary|:rnd] Where to count
    # @return [Integer]
    def count (which = :all, *args)
	if !args.empty? then values(which).count args[0]
	elsif block_given? then values(which).count { |item| yield item }
	else size which
	end
    end

    # #cycle is not implemented.

    # Set the default_proc block for generating default values.
    #
    # @param proc [Proc|nil] The proc block for default values.
    def default_proc= (proc)
	if proc.nil? || proc.is_a?(Proc) then @default_proc = proc
	else raise TypeError.new('Default_proc must be a Proc or nil')
	end
	proc
    end

    # #delete is not implemented. Use #delete_at, #delete_value,
    # #unset_at, or #unset_value instead.

    # Delete a specific index or key.
    #
    # (#delete_at alias since 2.0.0)
    def delete_at (key)
	return unset_at(key) if @negative_mode == :actual
	if key.is_a? Integer
	    res = nil
	    catch :index_error do
		key = _adjust_key key
		if key >= 0 && key < @seq.size
		    res = @seq.delete_at key
		    _scan_spr -1
		else
		    res = @spr.delete key
		    _scan_spr -1, key
		end
	    end
	    res
	else
	    @rnd.delete key
	end
    end

    alias_method :delete_key, :delete_at

    # Deletes each value for which the required block returns true.
    #
    # Subsequent values are re-indexed except when {#negative_mode=}
    # :actual. See also {#unset_if}.
    #
    # The block is passed the current value and nil for the sequential
    # and sparse arrays or the current value and key (in that order)
    # for the random-access hash.
    #
    #  s.delete_if(which) { |value, key| block }
    #
    # @param which [:all|:ary|:rnd] The data structures in which to delete.
    # @return [Sarah]
    # @since 2.0.0
    def delete_if (which = :all)
	if @negative_mode == :actual
	    return unset_if(which) { |value, key| yield value, key }
	end
	case which when :all, :ary
	    num_del = @seq.size
	    @seq.delete_if { |value| yield value, nil }
	    num_del -= @seq.size
	    new_spr = {}
	    @spr.keys.sort.each do |key|
		if yield @spr[key], nil then num_del += 1
		else new_spr[key - num_del] = @spr[key]
		end
	    end
	    @spr = new_spr
	    _scan_spr
	end
	case which when :all, :rnd
	    @rnd.delete_if { |key, value| yield value, key }
	end
	self
    end

    # Delete by value.
    #
    # Subsequent values are re-indexed except when {#negative_mode=} :actual.
    # See also {#unset_value}.
    #
    # @param what [Object] The value to be deleted
    # @param which [:all|:ary|:rnd] The data structures in which to delete.
    # @return [Sarah]
    def delete_value (what, which = :all)
	if @negative_mode == :actual
	    unset_if(which) { |value, key| value == what }
	else
	    delete_if(which) { |value, key| value == what }
	end
    end

    # #drop and #drop_while are not implemented.

    # Iterate a block (required) over each key and value like Hash#each.
    #
    #  s.each(which) { |key, value| block }
    #
    # (#each_key alias since 2.0.0)
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] The data structures over
    #  which to iterate. (Since 2.0.0)
    # @return [Sarah]
    def each (which = :all)
	case which when :all, :ary, :seq
	    @seq.each_index { |i| yield i, @seq[i] }
	end
	case which when :all, :ary, :spr
	    @spr.keys.sort.each { |i| yield i, @spr[i] }
	end
	case which when :all, :rnd
	    @rnd.each { |key, value| yield key, value }
	end
	self
    end

    alias_method :each_index, :each
    alias_method :each_key, :each
    alias_method :each_pair, :each

    # #each_value not implemented.

    # Is the array (or are parts of it) empty?
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] When data structures to check
    # @return [Boolean]
    # @since 2.0.0
    def empty? (which = :all)
	case which
	when :all then @seq.empty? && @spr.empty? && @rnd.empty?
	when :ary then @seq.empty? && @spr.empty?
	when :rnd then @rnd.empty?
	when :seq then @seq.empty?
	when :spr then @spr.empty?
	else true
	end
    end

    # Get a value by sequential or random-access key. If the key does not
    # exist, the local default or block value is returned. If no local or
    # block value is supplied, a KeyError exception is raised instead.
    #
    # If a local block is supplied, it is passed the key as a parameter.
    #
    #  fetch(key)
    #  fetch(key, default)
    #  fetch(key) { |key| block }
    #
    # @param key The key for the value to be returned.
    # @param default The value to return if the key does not exist.
    def fetch (key, *default)
	if key.is_a? Integer
	    # A key in the sequential array or sparse array hash?
	    key += @ary_next if key < 0 && @negative_mode != :actual
	    return @seq[key] if key >= 0 && key < @seq.size
	    return @spr[key] if @spr.has_key? key
	else
	    # A key in the random-access hash?
	    return @rnd[key] if @rnd.has_key? key
	end

	if !default.empty? then default[0]
	elsif block_given? then yield key
	else raise KeyError.new('Key not found')
	end
    end

    # #fill is not implemented.

    # Find the first index within the sequential or sparse array for
    # the specified value or yielding true from the supplied block.
    #
    #   find_index(value)
    #   find_index { |value| block }
    #
    # @return [Integer|nil]
    # @since 2.0.0
    def find_index (*args)
	if block_given?
	    index = @seq.index { |value| yield value }
	    return index unless index.nil?
	    @spr.keys.sort.each do |index|
		return index if yield @spr[index]
	    end
	else
	    value = args.pop
	    index = @seq.index value
	    return index unless index.nil?
	    @spr.keys.sort.each { |index| return index if @spr[index] == value }
	end
	nil
    end

    alias_method :index, :find_index

    # Return the first array value or first n array values.
    #
    #  obj = s.first
    #  list = s.first(n)
    #
    # @return [Object|Array]
    def first (*args); values(:ary).first(*args); end

    # Flatten sequential and sparse array values in place.
    #
    # @since 2.0.0
    def flatten! (*levels)
	if levels.empty? then @seq = values(:ary).flatten
	else @seq = values(:ary).flatten(levels[0])
	end
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # #frozen? is not implemented.

    # #hash is not implemented.

    # #initialize_copy is not implemented.

    # Return a string representation of this object.
    #
    # @since 2.0.0
    def inspect; self.class.name + (@seq + [@spr.merge(@rnd)]).to_s; end

    alias_method :to_s, :inspect

    # #invert is not implemented.

    # Return the sequential and sparse array values as a string,
    # separated by the supplied separator (or $, or the empty string).
    #
    # @param separator [String]
    # @return [String]
    # @since 2.0.0
    def join (separator = nil); values(:ary).join(separator || $, || ''); end

    # #keep_if is not implemented.

    # Test key/index existence.
    #
    # (#key? and #member? aliases since 2.0.0)
    #
    # @param key The key to check for existence.
    # @return [Boolean]
    def has_key? (key)
	if key.is_a? Integer
	    key += @ary_next if key < 0 && @negative_mode != :actual
	    (key >= 0 && key < @seq.size) || @spr.has_key?(key)
	else
	    @rnd.has_key? key
	end
    end

    alias_method :key?, :has_key?
    alias_method :member?, :has_key?

    # Test value presence.
    #
    # @param value The value for which to check presence.
    # @param which [:all|:ary|:rnd|:seq|:spr] Where to check for presence.
    # @return [Boolean]
    # @since 2.0.0
    def has_value? (value, which = :all)
	case which when :all, :ary, :seq
	    return true if @seq.include? value
	end
	case which when :all, :ary, :spr
	    return true if @spr.has_value? value
	end
	case which when :all, :rnd
	    return true if @rnd.has_value? value
	end
	false
    end

    alias_method :include?, :has_value?
    alias_method :value?, :has_value?

    # Insert arrays or Sarahs and merge hashes.
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to insert.
    # @return [Sarah]
    def insert! (*ahlist)
	ahlist.reverse_each do |ah|
	    if ah.is_a? Sarah
		unshift *ah.values(:ary)
		merge! ah.to_h(:rnd)
	    elsif ah.respond_to? :each_pair
		merge! ah
	    elsif ah.respond_to? :each_index
		unshift *ah
	    end
	end
	self
    end

    # Return the (first) key having the specified value.
    #
    # @param value The value for which the key is desired.
    # @param which [:all|:ary|:rnd] Where to search for the value.
    def key (value, which = :all)
	case which when :all, :ary
	    pos = index value
	    return pos unless pos.nil?
	end
	case which when :all, :rnd then return @rnd.key(value) end
	nil
    end

    # Return the random-access hash keys.
    #
    # @return [Array]
    # @deprecated Please use {#keys} instead.
    def rnd_keys; @rnd.keys; end

    # Return the sequential array keys (indexes).
    #
    # @return [Array<Integer>]
    # @deprecated Please use {#keys} instead.
    def seq_keys; 0...@seq.size; end

    # Return an array of indexes and keys.
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] Which indexes and keys
    #  to return. (Since 2.0.0)
    # @return [Array]
    def keys (which = :all)
	case which
	when :all then keys(:seq) + keys(:spr) + @rnd.keys
	when :ary then keys(:seq) + keys(:spr)
	when :rnd then @rnd.keys
	when :seq then (0...@seq.size).to_a
	when :spr then @spr.keys.sort
	else []
	end
    end

    # Return the last array value or last n array values.
    #
    #  obj = s.last
    #  list = s.last(n)
    #
    # @return [Object|Array]
    def last (*args); values(:ary).last(*args); end

    # Return the random-access hash size.
    #
    # @deprecated Please use {#size} instead.
    # @return [Integer]
    def rnd_length; @rnd.size; end

    alias_method :rnd_size, :rnd_length

    # Return the sequential array size.
    #
    # @deprecated Please use {#size} instead.
    # @return [Integer]
    def seq_length; @seq.size; end

    alias_method :seq_size, :seq_length

    # Return the number of stored values (AKA size or length).
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] The data structures
    #  for which the (combined) size is to be returned. (Since 2.0.0)
    # @return [Integer]
    def length (which = :all)
	size = 0
	case which when :all, :ary, :seq then size += @seq.size end
	case which when :all, :ary, :spr then size += @spr.size end
	case which when :all, :rnd then size += @rnd.size end
	size
    end

    alias_method :size, :length

    # Load/merge from a hash, array, or Sarah (beginning at key 0).
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to load/merge.
    # @return [Sarah]
    def merge! (*ahlist)
	ahlist.each do |ah|
	    if ah.respond_to? :each_pair
		ah.each_pair { |key, value| self[key] = value }
	    elsif ah.respond_to? :each_index
		ah.each_index { |i| self[i] = ah[i] }
	    end
	end
	self
    end

    alias_method :update, :merge!

    # Sets the negative mode, the manner in which negative integer
    # index/key values are handled.
    #
    #  :actual - Negative keys represent themselves and are not treated
    #    specially (although delete works like unset in this mode--values
    #    are not reindexed)
    #  :error (default) - Negative keys are interpreted relative to the
    #    end of the array; keys < -@ary_next raise an IndexError
    #  :ignore - Like :error, but keys < -@ary_next are treated as
    #    non-existent on fetch and silently ignored on set
    def negative_mode= (mode)
	case mode
	when :actual then @negative_mode = :actual
	when :error, :ignore
	    # These modes are only possible if there aren't currently
	    # any negative keys.
	    @negative_mode = mode if @ary_first >= 0
	end
	@negative_mode
    end

    # Return a new instance configured similarly to this one.
    #
    # @return [Sarah]
    # @since 2.0.0
    def new_similar (*args)
	opts = { :default => @default, :default_proc => @default_proc,
	  :negative_mode => @negative_mode }
	opts.merge! args.pop if !args.empty? && args[-1].is_a?(Hash)
	self.class.new(*args, opts)
    end

    # #pack is not implemented.

    # Return a hash of key/value pairs corresponding to the list of
    # keys/indexes.
    #
    # @return [Hash]
    # @since 2.0.0
    def pairs_at (*list)
	pairs = {}
	list.each { |key| pairs[key] = self[key] }
	pairs
    end

    # #permutation is not implemented.

    # Pop one or more values off the end of the sequential and sparse
    # arrays.
    #
    # @param count [Integer|nil] The number of items to pop (1 if nil).
    #  (Since 2.0.0)
    def pop (count = nil)
	if !count.nil?
	    max = size :ary
	    count = max if max < count
	    res = []
	    count.times { res << pop }
	    res.reverse
	elsif !@seq.empty? || !@spr.empty? then delete_at(@ary_next - 1)
	else @default_proc ? @default_proc.call(self, nil) : @default
	end
    end

    # #product is not implemented.

    # #rassoc is not implemented.

    # #reject is not implemented.

    # Rehash keys
    #
    # @return [Sarah]
    # @since 2.0.0
    def rehash; @spr.rehash; @rnd.rehash; self; end

    # #repeated_combination is not implemented.

    # #repeated_permutation is not implemented.

    # Replace contents with the contents of another array, hash, or Sarah.
    #
    # @param other [Sarah|hash]
    # @return [Sarah]
    def replace (other)
	clear
	negative_mode = other.negative_mode if other.is_a? Sarah
	merge! other
	self
    end

    # Reverse sequential and sparse array values into a sequential list.
    #
    # @return [Sarah]
    # @since 2.0.0
    def reverse!
	@seq = values(:ary).reverse
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # Iterate a block (required) over each key and value in reverse order
    # like Hash#each (first the random-access hash, then array values in
    # reverse key order).
    #
    #  s.reverse_each(which) { |key, value| block }
    #
    # @param which [:all|:ary|:seq|:spr] The data structures over
    #  which to iterate. The random-access hash is only included for :all.
    # @return [Sarah]
    # @since 2.0.0
    def reverse_each (which = :ary)
	case which when :all
	    @rnd.each { |key, value| yield key, value }
	end
	case which when :all, :ary, :spr
	    @spr.keys.sort.reverse_each { |i| yield i, @spr[i] }
	end
	case which when :all, :ary, :seq
	    (@seq.size - 1).downto(0) { |i| yield i, @seq[i] }
	end
	self
    end

    # Find the last index within the sequential or sparse array for
    # the specified value or yielding true from the supplied block.
    #
    #   rindex(value)
    #   rindex { |value| block }
    #
    # @return [Integer|nil]
    # @since 2.0.0
    def rindex (*args)
	if block_given?
	    @spr.keys.sort.reverse_each do |index|
		return index if yield @spr[index]
	    end
	    return @seq.rindex { |value| yield value }
	else
	    value = args.pop
	    @spr.keys.sort.reverse_each do |index|
		return index if @spr[index] == value
	    end
	    return @seq.rindex(value)
	end
    end

    # Return the sparse array and random-access hash (for
    # backward-compatibility only).
    #
    # @return [Hash]
    # @deprecated Please use {#to_h} instead.
    def rnd; @rnd; end

    # Return the sparse array and random-access hash values (for
    # backward-compatibility only).
    #
    # @return [Array]
    # @deprecated Please use {#values} instead.
    def rnd_values; @spr.values + @rnd.values; end

    # Rotate sequential and sparse array values into a sequential list.
    #
    # @param count [Integer] The amount to rotate. See Array#rotate!.
    # @return [Sarah]
    # @since 2.0.0
    def rotate! (count = 1)
	@seq = values(:ary).rotate(count)
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # Return a random sample from the sequential and sparse arrays
    # like Array#sample.
    #
    # @since 2.0.0
    def sample (*args); values(:ary).sample(*args); end

    # Select a subset of values as indicated by the supplied block and
    # return as a hash like Hash#select.
    #
    #  s.select(which) { |key, value| block }
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] Which values to select.
    def select (which = :all)
	to_h(which).select { |key, value| yield key, value }
    end

    # Return a copy of the sequential array values.
    #
    # @return [Array]
    # @deprecated Please use {#values} instead.
    def seq; Array.new(@seq); end

    alias_method :seq_values, :seq

    # Set values and/or key/value pairs (in standard Ruby calling syntax).
    #
    #  set(seq1, ..., seqN, key1 => val1, ..., keyN => valN)
    #
    # @param list [Array] A list of sequential values or random-access 
    #   key/value pairs to set.
    # @return [Sarah]
    def set (*list)
	hash = (list.size > 0 and list[-1].is_a? Hash) ? list.pop : nil
	merge! list
	merge! hash if hash
	self
    end

    # Set from a list of key/value pairs.
    #
    #  set_kv(key1, val1, ..., keyN, valN)
    #
    # @param kvlist [Array] The list of key/value pairs to set.
    # @return [Sarah]
    def set_kv (*kvlist)
	kvlist.each_slice(2) { |kv| self.[]=(*kv) }
	self
    end

    alias_method :set_pairs, :set_kv

    # Shift one or more values off the beginning of the sequential and
    # sparse arrays.
    #
    # Subsequent values are re-indexed unless {#negative_mode=} :actual.
    #
    # @param count [Integer|nil] The number of items to shift (1 if nil).
    #  (Since 2.0.0)
    def shift (count = nil)
	if !count.nil?
	    max = size :ary
	    count = max if max < count
	    res = []
	    count.times { res << shift }
	    res
	elsif !@seq.empty? || !@spr.empty? then delete_at @ary_first
	else @default_proc ? @default_proc.call(self, nil) : @default
	end
    end

    # Return the sequential and sparse array values in a shuffled
    # sequence like Array#shuffle.
    #
    #  shuffle
    #  shuffle(random: rng)
    #
    # @return [Array]
    # @since 2.0.0
    def shuffle (*args); values(:ary).shuffle(*args); end

    # Replaces the sequential and sparse array values with shuffled
    # sequential values.
    #
    #  shuffle!
    #  shuffle!(random: rng)
    #
    # @return [Sarah]
    # @since 2.0.0
    def shuffle! (*args)
	@seq = values(:ary).shuffle
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # Return an element or return a slice of elements from the sequential +
    # sparse array as a new Sarah.
    #
    # The original array is unmodified.
    #
    # NOTES: This implementation is new since 2.0.0 and incompatible with
    # prior versions. Alias #seq_slice is deprecated since 2.0.0.
    #
    #  s.slice(key)           # a single element (or nil)
    #  s.slice(start, length) # up to length elements at index >= start
    #  s.slice(range)         # elements with indexes within the range
    #
    # @return [Object|Sarah]
    # @since 2.0.0
    def slice (*args)
	case args.size
	when 1
	    if args[0].is_a? Range
		range = args[0]
		new_similar(:hash => pairs_at(*keys(:ary).select do |key|
		    range.include? key
		  end))
	    else fetch args[0], nil
	    end
	when 2
	    in_range = []
	    catch :index_error do
		start = _adjust_key args[0]
		in_range = keys(:ary).select { |key| key >= start }
	    end
	    new_similar(:hash => pairs_at(*in_range.slice(0, args[1])))
	else nil
	end
    end

    alias_method :seq_slice, :slice

    # Extract (delete) and return an element, or a slice of elements from
    # the sequential + sparse array as a new Sarah. Elements are unset
    # rather than deleted when {#negative_mode=} :actual.
    #
    # NOTES: This implementation is new since 2.0.0 and incompatible with
    # prior versions. Alias #seq_slice! is deprecated since 2.0.0.
    #
    #  s.slice!(key)           # a single element (or nil)
    #  s.slice!(start, length) # up to length elements at index >= start
    #  s.slice!(range)         # elements with indexes within the range
    #
    # @return [Object|Sarah]
    # @since 2.0.0
    def slice! (*args)
	case args.size
	when 1
	    if args[0].is_a? Range then res = slice *args
	    else return has_key?(args[0]) ? delete_key(args[0]) : nil
	    end
	when 2 then res = slice *args
	else return nil
	end
	res.reverse_each(:all) { |key, value| delete_key key }
    end

    alias_method :seq_slice!, :slice!

    # Return a sorted list of sequential and sparse array values.
    # Accepts an optional block to compare pairs of values.
    #
    #  s.sort
    #  s.sort { |a, b| block }
    #
    # @return [Array]
    # @since 2.0.0
    def sort
	if block_given? then values(:ary).sort { |a, b| yield a, b }
	else values(:ary).sort
	end
    end

    # Replace the sequential and sparse array values by a sorted
    # sequential list of values. Accepts an optional block to compare
    # pairs of values.
    #
    #  s.sort!
    #  s.sort! { |a, b| block }
    #
    # @return [Sarah]
    # @since 2.0.0
    def sort!
	if block_given? then @seq = values(:ary).sort { |a, b| yield a, b }
	else @seq = values(:ary).sort
	end
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # #sort_by is not implemented.

    # #take is not implemented.

    # #take_while is not implemented.

    # Return all or part of the structure in array representation.
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] The parts to represent.
    # @since 2.0.0
    def to_a (which = :all)
	ary, hsh = [], {}
	case which when :all, :ary, :seq then ary = @seq end
	case which when :all, :ary, :spr then hsh.merge! @spr end
	case which when :all, :rnd then hsh.merge! @rnd end
	ary + [hsh]
    end

    # Return all or part of the structure in hash representation.
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] The parts to represent.
    # @since 2.0.0
    def to_h (which = :all)
	hsh = {}
	case which when :all, :ary, :seq
	    @seq.each_index { |i| hsh[i] = @seq[i] }
	end
	case which when :all, :ary, :spr then hsh.merge! @spr end
	case which when :all, :rnd then hsh.merge! @rnd end
	hsh
    end

    # #transpose is not implemented.

    # Return unique sequential and sparse values as a sequential list.
    #
    #  s.uniq
    #  s.uniq { |item| block }
    #
    # @return [Array]
    # @since 2.0.0
    def uniq
	if block_given? then values(:ary).uniq { |item| yield item }
	else values(:ary).uniq
	end
    end

    # Replace sequential and sparse values with sequential unique values.
    #
    #  s.uniq!
    #  s.uniq! { |item| block }
    #
    # @return [Sarah]
    # @since 2.0.0
    def uniq!
	if block_given? then @seq = values(:ary).uniq { |item| yield item }
	else @seq = values(:ary).uniq
	end
	@ary_first, @ary_next, @spr = 0, @seq.size, {}
	self
    end

    # Unset a specific index or key (without reindexing other values).
    #
    # @since 2.0.0
    def unset_at (key)
	if key.is_a? Integer
	    res = nil
	    catch :index_error do
		key = _adjust_key key
		if key >= 0 && key < @seq.size
		    _seq_to_spr key + 1
		    res = @seq.pop
		else
		    res = @spr.delete key
		end
		_scan_spr
	    end
	    res
	else
	    @rnd.delete key
	end
    end

    alias_method :unset_key, :unset_at

    # Unsets each value for which the required block returns true.
    #
    # Subsequent values are never re-indexed. See also {#delete_if}.
    #
    # The block is passed the current value and index for the sequential
    # and sparse arrays or the current value and key (in that order)
    # for the random-access hash.
    #
    #  s.unset_if { |value, key| block }
    #
    # @param which [:all|:ary|:rnd] The data structures in which to unset.
    # @since 2.0.0
    # @return [Sarah]
    def unset_if (which = :all)
	case which when :all, :ary
	    @seq.each_index do |index|
		if yield @seq[index], index
		    unset_at index
		    break	# Any other sequentials are now sparse
		end
	    end
	    @spr.keys.sort.each do |key|
		@spr.delete(key) if yield @spr[key], key
	    end
	    _scan_spr
	end
	case which when :all, :rnd
	    @rnd.delete_if { |key, value| yield value, key }
	end
	self
    end

    # Unset by value.
    #
    # Subsequent values are never re-indexed. See also {#delete_value}.
    #
    # @param what [Object] The value to be deleted
    # @param which [:all|:ary|:rnd] The data structures in which to unset.
    # @return [Sarah]
    # @since 2.0.0
    def unset_value (what, which = :all)
	unset_if(which) { |value, key| value == what }
    end

    # Unshift (insert) sequential values onto the beginning of the
    # sequential or sparse array.
    #
    # Subsequent values are re-indexed except when {#negative_mode=} :actual.
    #
    # @param vlist [Array] A list of values to unshift (insert).
    # @return [Sarah]
    def unshift (*vlist)
	if @negative_mode == :actual
	    vlist.reverse_each do |value|
		@ary_first -= 1
		self[@ary_first] = value
	    end
	else
	    _scan_spr vlist.size
	    @seq.unshift *vlist
	end
	self
    end

    # Return an array of values.
    #
    # @param which [:all|:ary|:rnd|:seq|:spr] Which values to return.
    #  (Since 2.0.0)
    # @return [Array]
    def values (which = :all)
	case which
	when :all then @seq + values(:spr) + @rnd.values
	when :ary then @seq + values(:spr)
	when :rnd then @rnd.values
	when :seq then Array.new @seq
	when :spr then @spr.values_at(*@spr.keys.sort)
	else []
	end
    end

    # Return the values corresponding to the list of keys/indexes.
    #
    # @return [Array]
    # @since 2.0.0
    def values_at (*list); list.collect { |key| self[key] }; end

    # Zip sequential and sparse array values with other arrays.
    # See Array#zip.
    #
    # @return [Array]
    # @since 2.0.0
    def zip (*args); values(:ary).zip(*args); end

    ##### Protected methods #####

    protected

    def _adjust_key (key)
	case @negative_mode
	when :error
	    raise IndexError.new('Index is too small') if key < -@ary_next
	when :ignore
	    throw :index_error, nil if key < -@ary_next
	end
	if key < 0 && @negative_mode != :actual then key + @ary_next
	else key
	end
    end

    # Extract integer-keyed or other parts from a hash
    def _hash_filter (h, type)
	case type
	when :array then h.select { |k, v| k.is_a?(Integer) && k >= 0 }
	when :other then h.select { |k, v| !k.is_a?(Integer) || k < 0 }
	end
    end

    # Scan the sparse array for min and max, possibly adjusting keys
    # as we go.
    def _scan_spr (adjustment = 0, from = 0)
	@ary_first = @seq.empty? ? nil : 0
	@ary_next = @seq.size

	adj = {}		# adjusted sparse array
	@spr.each do |key, value|
	    if adjustment != 0
		key += adjustment if key >= from
		adj[key] = value
	    end
	    @ary_first = key if !@ary_first || key < @ary_first
	    @ary_next = key + 1 if key >= @ary_next
	end
	@ary_first ||= 0
	@spr = adj unless adj.empty?
    end

    # Migrate selected sequential values to the sparse hash.
    def _seq_to_spr (index = 0)
	(@seq.size - 1).downto(index) { |i| @spr[i] = @seq.pop }
    end

    # Migrate newly adjacent sparse values to the sequential array.
    def _spr_to_seq
	@seq.push @spr.delete(@seq.size) while @spr.has_key? @seq.size
    end

end

# END
