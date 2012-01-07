
# ruby convert_data.rb *.json.* 1> input_data 2> training_data
# ./svm-train -c 64 -nu 0.00048828125 training_data && ./svm-predict input_data training_data.model webkit.out && paste input_data webkit.out

require 'ostruct'
require 'json'
require './webkit'

raw_inputs =[]

throw "input files please" if ARGV.length == 0

ARGV.each { |filename|
  inputs_from_file = JSON.parse(IO.read(filename))
  raw_inputs +=inputs_from_file
}

merged_inputs = raw_inputs.reduce({}) { |acc, input|
  svn_rev = input["svn_rev"]
  existing = acc[svn_rev] || {}
  acc[svn_rev] = existing.merge(input) { |key, old_value, new_value|
    case key
      when "svn_rev"
        throw "different svn_revs wtf #{old_value} vs. #{new_value}" unless old_value == new_value
        old_value
      when "crbug"
        #puts "different crbugs #{old_value} vs. #{new_value}" unless old_value == new_value
        old_value
      when "branch"
        old_value + new_value
      when "merged_by"
        (old_value + new_value).uniq
      when "tbr_by_security_team"
        old_value || new_value
      when "merge_by_security_team"
        old_value || new_value
      when "keywords"
        (old_value + new_value).uniq
      when "crash_in_patch"
         old_value || new_value
      when "restricted_bug"
        old_value || new_value
      else
        throw "duplicate keys: #{svn_rev} - #{key} - v1: #{old_value} (#{existing["branch"]}) v2: #{new_value} (#{input["branch"]})" unless old_value == new_value
        old_value
    end
  }
  acc
}

File.open("merged.json", "w") { |f|
  f.puts(merged_inputs.values.to_json)
}

inputs = merged_inputs.values.map { |h| OpenStruct.new(h) }
inputs.sort! { |a, b| a.svn_rev.to_i <=> b.svn_rev.to_i }

trainings = inputs.select { |c| (c.desired_output = WebKit::KNOWN[c.svn_rev]) != nil }

INTERESTING_MERGERS = trainings.select(&:desired_output).map(&:merged_by).flatten.uniq.compact.sort
INTERESTING_COMMITTERS = trainings.select(&:desired_output).map(&:committer).flatten.uniq
ALL_KEYWORDS = inputs.map(&:keywords).flatten.uniq.compact.sort

def an_input(c)
  [
      c.by_security_team ? 1 : 0,
      c.review_by_security_team ? 1 : 0,
      c.mentions_security_team ? 1 : 0,
      c.restricted_bug ? 1 : 0,
      c.crash_in_patch ? 1 : 0,
      c.merged ? 1 : 0,
      c.merge_by_security_team ? 1 : 0,
      c.tbr_by_security_team ? 1 : 0,      
  ]
end

def line(desired_output, c)
  features = []
  feature_index = 1
  an_input(c).each_with_index { |f, i| features << "%d:%d" % [i+feature_index, f] }
  feature_index += features.length

  committer_feature = "%d:1" % (feature_index + INTERESTING_COMMITTERS.index(c.committer)) if INTERESTING_COMMITTERS.include? c.committer
  features << committer_feature if committer_feature
  feature_index += INTERESTING_COMMITTERS.length

  merger_feature = []
  c.merged_by.sort.each { |merger|
    merger_feature << "%d:1" % (feature_index + INTERESTING_MERGERS.index(merger)) if INTERESTING_MERGERS.include? merger
  } if c.merged
  features << merger_feature.join(" ")
  feature_index += INTERESTING_MERGERS.length

  keywords = c.keywords || []
  keyword_features = keywords.sort.map { |k| "%d:1" % (feature_index + ALL_KEYWORDS.index(k)) }
  features += keyword_features
  "#{desired_output} #{features.join(" ")} ##{c.svn_rev} #{keywords.join(", ")} #{c.merged ? "merged" : ""}"
end

to_number = {
    "yes" => 1,
    "no" => -1,
    "maybe" => 0
}

trainings.each { |c|
  STDERR.puts line(to_number[c.desired_output], c)
}

(inputs-trainings).each { |c|
  puts line(0, c)
}