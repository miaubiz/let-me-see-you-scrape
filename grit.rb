require './webkit'

module Grit
  class Commit

    BUG = /^.*(https|bug).*?([^[:digit:]]?)([[:digit:]]{5})($|[^[:digit:]])/i
    SVN_REV = /git-svn-id: http:\/\/svn.webkit.org\/repository\/webkit\/(?:trunk|branches\/chromium\/...)@([0-9]*) /
    REVIEW = /^ *Reviewed by.*(#{WebKit::SECURITY_TEAM_NAMES.join("|")}).*$/
    TBR = /TBR=(#{WebKit::SECURITY_TEAM.join("|")})/
    MENTION = /^.*?(20[0-9]{2}-[0-9]{2}-[0-9]{2})?(.*)?(#{WebKit::SECURITY_TEAM_NAMES.join("|")}).*$/
    MERGE = /Merge[: r]+([0-9]+)/
    CRBUG = /(?:BUG|ISSUE|crbug)[= ]([0-9]+)/

    KEYWORDS = /crash|rebaseline|use.after.free|flak|cve-20|heap|bad.cast|rolling out|out.of.bounds|buffer.overflow|unreviewed|broke|build|security|origin|policy|null|deref|stale|danger|corrupt|cleared/

    def fix?
      !!(message=~BUG)
    end

    def bug
      message.match(BUG)[3].to_i
    end

    def restricted_bug?
      !!(fix? && WebKit::RESTRICTED_BUGS.include?(bug))
    end

    def by_security_team?
      WebKit::SECURITY_TEAM.include?(committer.to_s)
    end

    def reviewed_by_security_team?
      !!(REVIEW=~message)
    end


    def tbr_by_security_team?
      !!(TBR=~message)
    end

    def mentions_security_team?
      !!(MENTION=~message && !reviewed_by_security_team?)
    end

    def crash?
      !!(message=~/crash/i)
    end

    def keywords
      message.downcase.scan(KEYWORDS).uniq
    end

    def crash_in_patch?
      begin
        !!(to_patch=~/crash/i)
      rescue
        puts "native git timed out when creating patch for #{svn_rev}"
      end
    end

    def svn_rev
      message.match(SVN_REV)[1]
    end

    def merge?
      !!(message=~MERGE)
    end

    def merge_rev
      message.match(MERGE)[1]
    end

    def crbug?
      !!(message=~CRBUG)
    end

    def crbug
      message.match(CRBUG)[1]
    end

  end
end
