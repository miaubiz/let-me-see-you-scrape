require 'grit'
require 'json'
require './grit'
require './webkit'

include Grit

repo = Repo.new(ENV['WEBKIT_ROOT'])

repo.heads.reject { |b| b.name=="master" }.each { |branch|
  puts "-------------------------------"
  puts "branch: #{branch.name}"
  to_json = []
  repo.commits(branch.name, 1500).map { |c|
    if c.merge? then
      json_commit = {
          :svn_rev => c.merge_rev,
          :merged => true,
          :merged_by => [c.committer.to_s],
          :merge_by_security_team => c.by_security_team?,
          :tbr_by_security_team => c.tbr_by_security_team?,
          :branch => [branch.name]
      }

      json_commit[:crbug] = c.crbug if c.crbug?

      to_json.push(json_commit)

    end
  }

  File.open("merge.json.#{branch.name}", "w") { |f|
    puts "saving file... #{branch.name}"
    f.puts(to_json.to_json)
  }
}