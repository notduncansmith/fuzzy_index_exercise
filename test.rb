require_relative 'fuzzy_index'
require 'test/unit'
require 'pp'

class FuzzyIndexTest < Test::Unit::TestCase
  def test_exact_match
    f = FuzzyIndex.new
    f.add 'joe'

    assert_equal f.query('joe'), ['joe']
  end

  def test_prefix_match
    f = FuzzyIndex.new
    f.add 'joe'

    assert_equal f.query('jo'), ['joe']
  end

  def test_middle_match
    f = FuzzyIndex.new
    f.add 'joseph'

    assert_equal f.query('se'), ['joseph']
  end

  def test_excludes_non_matching
    f = FuzzyIndex.new
    f.add 'joe'
    f.add 'jack'

    assert_equal f.query('jo'), ['joe']
  end

  def test_no_matches
    f = FuzzyIndex.new
    f.add 'joe'
    f.add 'jack'

    assert_equal f.query('jill'), []
  end

  def test_rank_by_weight
    f = FuzzyIndex.new
    f.add 'john'
    f.add 'joey'

    assert_equal f.query('joe'), ['joey', 'john']
  end

  def test_exact_match_tiebreaker
    f = FuzzyIndex.new
    f.add 'john'
    f.add 'joey'
    f.add 'joe'

    assert_equal f.query('joe'), ['joe', 'joey', 'john']
  end

  def test_insertion_order_tiebreaker
    f = FuzzyIndex.new
    f.add 'john'
    f.add 'joe'

    assert_equal f.query('jo'), ['john', 'joe']
  end

  def test_case_handling
    f = FuzzyIndex.new

    f.add 'johnny'
    f.add 'JoHnNY'
    f.add 'jOhnNy'

    assert_equal f.query('johnny'), ['johnny', 'JoHnNY', 'jOhnNy']
    assert_equal f.query('JoHnNY'), ['JoHnNY', 'johnny', 'jOhnNy']
    assert_equal f.query('johnNy'), ['johnny', 'JoHnNY', 'jOhnNy']
  end

  def test_max_results
    f = FuzzyIndex.new

    f.add 'aaa'
    f.add 'aac'
    f.add 'aab'

    assert_equal f.query('aa', max_results: 2), ['aaa', 'aac']
  end

  def test_include_weights
    f = FuzzyIndex.new
    f.add 'joe'
    f.add 'johnny'

    assert_equal f.query('jo', include_weights: true), [['joe', 5], ['johnny', 5]]
  end

  def test_removal
    f = FuzzyIndex.new

    f.add 'joe'

    f.add('john')
    .add('joey')
    .remove('joe')

    assert_equal f.query('joe'), ['joey', 'john']
  end

  def test_argument_validation
    f = FuzzyIndex.new(max_input_length: 5)

    too_short = 'a'
    too_long = 'a'*6
    not_a_string = 24

    assert_raise(ArgumentError) { f.add too_short }
    assert_raise(ArgumentError) { f.query too_short }
    assert_raise(ArgumentError) { f.remove too_short }

    assert_raise(ArgumentError) { f.add too_long }
    assert_raise(ArgumentError) { f.query too_long }
    assert_raise(ArgumentError) { f.remove too_long }

    assert_raise(ArgumentError) { f.add not_a_string }
    assert_raise(ArgumentError) { f.query not_a_string }
    assert_raise(ArgumentError) { f.remove not_a_string }
  end
end