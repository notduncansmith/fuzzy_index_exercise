# FuzzyIndex

FuzzyIndex stores a list of string values and indexes them for fuzzy-matching.

The fuzzy-match algorithm is a simple bigram-proximity index. Results are weighted by how closely their bigrams align with those of the search string.

While it's not often you want a process like fuzzy suggestions to be implemented in pure Ruby, sometimes you do; for those moments, FuzzyIndex is here... waiting... patiently...


## Usage

```ruby
f = FuzzyIndex.new

f.add 'john'
f.add 'joey'
f.add 'joe'

pp f.query('joe', include_weights: true)
# [["joe", 11], ["joey", 10], ["john", 5]]

assert_equal f.query('joe'), ['joe', 'joey', 'john']

f.remove 'joe'

assert_equal f.query('joe'), ['joey', 'john']
```

To run tests:

```sh
ruby test.rb
```

To run benchmarks (requires running `bundle install` first):

```sh
ruby benchmarks.rb
```

## Design Notes

### Preface

This is a Ruby code sample written as an exercise, not a library intended for serious use.

### Why a bigram index?

The principal value of fuzzy search in this scenario is in rediscovery of some user (and subsequently the content on their profile) via remembered fragments of their username, while also supporting the "typed quickly and sloppily" use-case.

To this end, 2 seems to be the magic `n` value for giving proper weight to correctness, combined with fuzziness to reduce the required order/length accuracy (`_` characters can always be used to fill in blanks), for these sized values and queries. A more flexible n-gram index seems fun to build, but beyond the scope of this project.

### Internal structure

The `store` contains a mapping from cheap integer keys to the raw strings stored. Since usernames would likely (though not necessarily) be associated with similarly cheap user ids, we probably wouldn't normally take this approach. That said, the store construct here allows us to simulate this, and consequently use cheap ids in the bigram index.

### Secure defaults

Because this would presumably be accepting search input from users, there are maximum sizes available on query length and indexed value length (though in any serious use, as terrifying as that thought is, I'd hope these pathological inputs would be handled before they reach this CPU-heavy Ruby library).