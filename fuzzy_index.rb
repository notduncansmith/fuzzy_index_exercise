class FuzzyIndex
  attr_accessor :store
  attr_accessor :reverse_store
  attr_accessor :bigram_index

  def initialize(max_input_length: 60)
    @max_input_length = max_input_length
    @store = Hash.new # {1 => "usErnAmE", 2 => "other_username"}
    @reverse_store = Hash.new # {"usErnAmE" => 1, "other_username" => 2}
    @bigram_index = Hash.new # {"us" => {1 => {1=>true}}, "ot" => {1 => {2=>true}}, "se" => {2 => {1=>true}}, "th" => {2 => {2=>true}}}
  end

  def add(raw_value)
    value = compatible_string(raw_value, label: 'Indexed value')

    if @reverse_store[raw_value]
      # already indexed
      return self
    end

    key = @store.keys.length

    @store[key] = raw_value
    @reverse_store[raw_value] = key

    FuzzyIndex.bigrams(value).each_with_index do |b, i|
      @bigram_index[b] ||= Hash.new
      @bigram_index[b][i] ||=  Hash.new
      @bigram_index[b][i][key] = true
    end

    self
  end

  def remove(raw_value)
    value = compatible_string(raw_value, label: 'Removed value')
    key = @reverse_store[raw_value]

    if key.nil?
      # Welp, looks like our work here is done
      return self
    end

    @store.delete(key)
    @reverse_store.delete(raw_value)

    FuzzyIndex.bigrams(value).each_with_index do |bg, i|
      @bigram_index[bg][i].delete(key)
    end

    self
  end

  def keys_for(bigram:, at_position:)
    positions = @bigram_index[bigram] || Hash.new
    (positions[at_position] || Hash.new).keys
  end

  def query(raw_search_string, max_results: 20, include_weights: false)
    search_string = compatible_string(raw_search_string, label: 'Search string')
    existing_key = @reverse_store[raw_search_string]

    offsets = -5...5 # todo: make this configurable
    search_bigrams = FuzzyIndex.bigrams(search_string)

    # This is an array of {key=>weight} maps
    weighted_keys_per_bigram = search_bigrams.each_with_index.map do |b, i|
      offsets.reduce(Hash.new) do |acc, offset|
        keys_for(bigram: b, at_position: i + offset).each do |key|
          proximity = (offsets.max + 1) - offset.abs
          weight = (acc[key] || 0) + proximity
          acc[key] = weight
        end

        acc
      end
    end

    weighted_keys = weighted_keys_per_bigram.reduce(Hash.new) do |acc, weights|
      acc.merge!(weights) { |key, oldval, newval| oldval + newval }
    end

    if existing_key
      weighted_keys[existing_key] += 1
    end

    weighted_keys
    .keys
    .sort { |a,b| weighted_keys[b] <=> weighted_keys[a] } # descending sort
    .take(max_results)
    .map do |key|
      if include_weights
        [@store[key], weighted_keys[key]]
      else
        @store[key]
      end
    end
  end

  # Raises if value is not a 2+ character string
  # Returns downcased value
  def compatible_string(value, label: 'Argument')
    unless value.is_a? String
      raise ArgumentError, "#{label} must be a String"
    end

    unless value.length >= 2
      raise ArgumentError, "#{label} must be 2 or more characters long"
    end

    unless value.length < @max_input_length
      raise ArgumentError, "#{label} must be less than #{@max_input_length} characters long"
    end

    value.downcase
  end

  # Returns all adjacent pairs of characters for a given string
  # "username" -> ["us", "se", "er", "rn", "na", "am", "me"]
  def self.bigrams(str)
    letters = str.split('')

    # This leaves the last letter by itself at the end
    bigrams_with_tail = letters.each_with_index.map do |letter, i|
      next_index = i + 1
      next_letter = (next_index == letters.length) ? '' : letters[next_index]
      letter + next_letter
    end

    # So we'll use a range to remove it
    bigrams_with_tail[0...-1]
  end
end
