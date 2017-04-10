require_relative 'fuzzy_index'
require 'benchmark'
require 'pp'
require 'faker'

puts "Generating benchmark data, hang tight..."

names = []

for i in 0...50_000; names << Faker::Internet.user_name(5...32); end

Benchmark.bm(15) do |b|

  f = FuzzyIndex.new
  b.report("50k inserts:") { for i in 1...50_000; f.add(names[i]); end }

  b.report("1k queries:") { for i in 1...1_000; f.query(names[i][2..6]); end }
end