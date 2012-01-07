require 'grit'
require 'json'
require './grit'
require './webkit'

include Grit

repo = Repo.new(ENV['WEBKIT_ROOT'])

step = 1000
(0..110000).step(step).map { |n|
  to_json = []
  repo.commits('master', step, n).map { |c|
    json_commit = {
        :svn_rev => c.svn_rev,
        :committer => c.committer.to_s,
        :by_security_team => c.by_security_team?,
        :reviewed_by_security_team => c.reviewed_by_security_team?,
        :mentions_security_team => c.mentions_security_team?,
        :restricted_bug => c.restricted_bug?,
        :keywords => c.keywords,
        :crash_in_patch => c.crash_in_patch?
    }

    json_commit[:bug] = c.bug if c.fix?

    to_json.push(json_commit)
  }
  File.open("commits.json.#{n}", "w") { |f|
    puts "saving file... #{n}"
    f.puts(to_json.to_json)
  }
}

