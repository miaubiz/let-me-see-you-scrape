require 'open-uri'
(75216..100000).each { |x|
    actual = x
    STDERR.puts "at #{actual}"
    open("https://bugs.webkit.org/show_bug.cgi?id=#{actual}")  { |f|
        f.each { |l| 
            puts l if /You are not authorized/=~l 
            STDERR.puts l if /You are not authorized/=~l
            STDERR.puts "no more bugs: #{l}" if /Bug ##{actual} does not exist/=~l
        } 
    }
}
