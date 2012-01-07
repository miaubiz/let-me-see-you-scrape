require 'open-uri'
(68700..76000).each { |x|
    actual = x
    STDERR.puts "at #{actual}"
    open("https://bugs.webkit.org/show_bug.cgi?id=#{actual}")  { |f|
        f.each { |l| 
            puts l if /You are not authorized/=~l 
            STDERR.puts l if /You are not authorized/=~l
        } 
    }
}
