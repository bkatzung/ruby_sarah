# Sarah - Combination sequential array/random-access hash
#
# Sequential values beginning at key (index) 0 are stored in an array.
# Values with sparse or non-numeric keys are stored in a hash. Values
# may migrate between the two if holes in the sequential key sequence
# are created or removed.
#
# @author Brian Katzung <briank@kappacs.com>, Kappa Computer Solutions, LLC
# @copyright 2013 Brian Katzung and Kappa Computer Solutions, LLC
# @license MIT License

class Sarah

    # @!attribute default
    # The default value returned for non-existent keys.
    attr_accessor :default

    # @!attribute default_proc
    # @return [Proc]
    # The default proc to call for non-existent keys. This takes precedence
    # over the default value. It is passed the Sarah and the referenced key
    # (or nil) as parameters.
    attr_accessor :default_proc

    # Initialize a new instance.
    #
    # If passed a block, the block is called to provide default values
    # instead of using the :default option value. The block is passed the
    # hash and the requested key (or nil for a shift or pop on an empty
    # sequential array).
    #
    # @param opts [Hash] Setup options.
    # @option opts :default The default value to return for a non-existent key.
    # @option opts [Proc] :default_proc The default proc to call for a
    #   non-existent key.
    # @option opts [Array, Hash] :array An array (or hash!) to use for
    #   initialization (first).
    # @option opts [Hash, Array] :hash A hash (or array!) to use for
    #   initialization (second).
    # @option opts [Array, Hash] :from An array or hash to use for
    #   initialization (third).
    def initialize (opts = {}, &block)
	clear
	@default = opts[:default]
	@default_proc = block || opts[:default_proc]
	merge! opts[:array], opts[:hash], opts[:from]
    end

    # Clear all sequential array and random-access hash values.
    #
    # @return [Sarah]
    def clear
	@seq = []
	@rnd = {}
	self
    end

    # Test key existence.
    #
    # @param key The key to check for existence.
    # @return [Boolean]
    def has_key? (key)
	@rnd.has_key?(key) or (key.is_a? Integer and
	  key >= -@seq.size and key < @seq.size)
    end

    # Get a value by sequential or random-access key. If the key does not
    # exist, the default value or initial block value is returned. If
    # called with a range or an additional length parameter, a slice is
    # returned instead.
    #
    # @param key The key for the value to be returned, or a range.
    # @param len [Integer] An optional slice length.
    # @return [Object, Array]
    def [] (key, len = nil)
	if len
	    slice(key, len)
	elsif key.is_a? Range
	    slice(key)
	elsif @rnd.has_key? key
	    @rnd[key]
	elsif key.is_a? Integer and key >= -@seq.size and key < @seq.size
	    @seq[key]
	else
	    @default_proc ? @default_proc.call(self, key) : @default
	end
    end

    # Get a value by sequential or random-access key. If the key does not
    # exist, the local default or block value is returned. If no local or
    # block value is supplied, a KeyError exception is raised instead.
    #
    # If a local block is supplied, it is passed the key as a parameter.
    #
    # @param key The key for the value to be returned.
    # @param default The value to return if the key does not exist.
    def fetch (key, *default)
	if @rnd.has_key? key
	    @rnd[key]
	elsif key.is_a? Integer and key >= -@seq.size and key < @seq.size
	    @seq[key]
	elsif default.size > 0
	    default[0]
	elsif block_given?
	    yield key
	else
	    raise KeyError.new("key not found: #{key}")
	end
    end

    # Shift and return the first sequential array value.
    #
    # @return Object
    def shift
	if @seq.size > 0
	    @seq.shift
	elsif @default_proc
	    @default_proc.call self, nil
	else
	    @default
	end
    end

    # Pop and return the last sequential array value
    def pop
	if @seq.size > 0
	    @seq.pop
	elsif @default_proc
	    @default_proc.call self, nil
	else
	    @default
	end
    end

    # Iterate a block (required) over each key and value.
    #
    # @return [Sarah]
    def each
	@seq.each_index { |i| yield(i, @seq[i]) }
	@rnd.each { |kv| yield(*kv) }
	self
    end

    alias_method :each_pair, :each

    # Iterate a block (required) over each key.
    #
    # @return [Sarah]
    def each_index
	@seq.each_index { |i| yield(i) }
	@rnd.keys.each { |k| yield(k) }
	self
    end

    # Set a value by sequential or random-access key.
    #
    # @param key The key for which the value should be set.
    # @param value The value to set for the key.
    # @return Returns the value.
    def []= (key, value)
	if key.is_a? Integer and key.abs <= @seq.size
	    key += @seq.size if key < 0
	    @seq[key] = value
	    @rnd.delete key
	else
	    @rnd[key] = value
	end

	# Move adjacent random-access keys to the sequential array
	key = @seq.size
	while @rnd.has_key? key
	    @seq[key] = @rnd.delete key
	    key += 1
	end

	value
    end

    # Set values and/or key/value pairs.
    #
    # <tt>set([val1, ..., valN,] [key1 => kval1, ..., keyN => kvalN])</tt>
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

    # Set key/value pairs.
    #
    # <tt>set_kv(key1, val1, ..., keyN, valN)</tt>
    #
    # @param kvlist [Array] The list of key/value pairs to set.
    # @return [Sarah]
    def set_pairs (*kvlist)
	kvlist.each_slice(2) { |kv| self.[]=(*kv) }
	self
    end

    alias_method :set_kv, :set_pairs

    # Append arrays/Sarahs (or merge hashes) of values.
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to append.
    # @return [Sarah]
    def append! (*ahlist)
	ahlist.each do |ah|
	    if ah.respond_to? :seq_values and ah.respond_to? :rnd
		push *ah.seq_values
		merge! ah.rnd
	    elsif ah.respond_to? :each_pair
		merge! ah
	    elsif ah.respond_to? :each_index
		push *ah
	    end
	end
	self
    end

    # Insert arrays/Sarahs (or merge hashes) of values.
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to insert.
    # @return [Sarah]
    def insert! (*ahlist)
	ahlist.reverse_each do |ah|
	    if ah.respond_to? :seq_values and ah.respond_to? :rnd
		unshift *ah.seq_values
		merge! ah.rnd
	    elsif ah.respond_to? :each_pair
		merge! ah
	    elsif ah.respond_to? :each_index
		unshift *ah
	    end
	end
	self
    end

    # Load/merge from a hash and/or array/Sarah (beginning at key 0).
    #
    # @param ahlist [Array<Array, Hash, Sarah>] The structures to load/merge.
    # @return [Sarah]
    def merge! (*ahlist)
	ahlist.each do |ah|
	    if ah.respond_to? :each_pair
		ah.each_pair { |kv| self.[]=(*kv) }
	    elsif ah.respond_to? :each_index
		ah.each_index { |i| self[i] = ah[i] }
	    end
	end
	self
    end

    alias_method :update, :merge!

    # Unshift (insert) sequential values beginning at key 0.
    #
    # @param vlist [Array] A list of values to unshift (insert).
    # @return [Sarah]
    def unshift (*vlist)
	(@seq.size...@seq.size+vlist.size).each { |k| @rnd.delete k }
	@seq.unshift *vlist
	self
    end

    # Push (append) sequential values.
    #
    # @param vlist [Array] A list of values to push (append).
    # @return [Sarah]
    def push (*vlist)
	(@seq.size...@seq.size+vlist.size).each { |k| @rnd.delete k }
	@seq.push *vlist
	self
    end

    alias_method :<<, :push

    # Delete by sequential or random-access key, returning any existing value
    # (or the default or block value, otherwise).
    #
    # @param key The key to be deleted.
    # @return The value of the deleted key.
    def delete_key (key)
	return @rnd.delete key if @rnd.has_key? key
	if key.is_a? Integer
	    key += @seq.size if key < 0
	    if key >= 0 and key < @seq.size
		result = @seq[key]

		# Move any following keys to the random-access hash
		(key+1...@seq.size).each { |i| @rnd[i] = @seq[i] }

		# Truncate the sequential array
		@seq = @seq[0...key]

		return result
	    end
	end
	@default_proc ? @default_proc.call(self, nil) : @default
    end

    # Return the sequential array size.
    #
    # @return [Integer]
    def seq_size; @seq.size; end

    # Return the random-access hash size.
    #
    # @return [Integer]
    def rnd_size; @rnd.size; end

    # Return the total size.
    #
    # @return [Integer]
    def size; @seq.size + @rnd.size; end

    alias_method :seq_length, :seq_size
    alias_method :rnd_length, :rnd_size
    alias_method :length, :size

    # Return the sequential-access array.
    #
    # @return [Array]
    def seq; @seq; end

    # Return the random-access hash.
    #
    # @return [Hash]
    def rnd; @rnd; end

    # Return the sequential array keys (indexes).
    #
    # @return [Array<Integer>]
    def seq_keys; 0...@seq.size; end

    # Return the random-access hash keys.
    #
    # @return [Array]
    def rnd_keys; @rnd.keys; end

    # Return all the keys.
    #
    # @return [Array]
    def keys; seq_keys.to_a + rnd_keys; end

    # Return the hash values.
    def rnd_values; @rnd.values; end

    # Return all the values.
    def values; @seq + @rnd.values; end

    alias_method :seq_values, :seq

    # Slice all.
    #
    # @return [Sarah, Object]
    def slice (*params)
	res = @seq.slice *params
	(res.is_a? Array) ? (self.class.new :array => res, :hash => @rnd,
	  :default_proc => @default_proc, :default => @default) : res
    end

    # Slice all in place.
    #
    # @return [Sarah, Object]
    def slice! (*params)
	res = @seq.slice! *params
	(res.is_a? Array) ? (self.class.new :array => res, :hash => @rnd,
	  :default_proc => @default_proc, :default => @default) : res
    end

    # Slice sequential.
    #
    # @return [Sarah, Object]
    def seq_slice (*params)
	res = @seq.slice *params
	(res.is_a? Array) ? (self.class.new :array => res,
	  :default_proc => @default_proc, :default => @default) : res
    end

    # Slice sequential in place.
    #
    # @return [Sarah, Object]
    def seq_slice! (*params)
	res = @seq.slice! *params
	(res.is_a? Array) ? (self.class.new :array => res,
	  :default_proc => @default_proc, :default => @default) : res
    end

end
