#!/usr/bin/env ruby

begin
  raise "Invalid argument" if ARGV.size != 2

  from_str, to_str = ARGV
  begin
    from = eval(from_str)
  rescue
    from = from_str
  end

  print "from:"
  p from

  files = `git ls-files`
  files.lines.each do |path|
    path.strip!
    buf = nil
    open(path) do |f|
      old_buf = f.read
      begin
        if from =~ old_buf
          print "match:#{path}"
          buf = eval("old_buf.gsub(from, \"#{to_str}\")")
          buf = nil if old_buf == buf
        end
      rescue => ex
        #puts "path:#{path}"
        #p ex
        next
      end
    end
    if buf
      puts "change: #{path}"
      open(path, "w") do |f|
        f.write buf
      end
    end
  end
rescue => ex
  puts ex.message
  print <<EOS
Usage:
ruby #{File.basename(__FILE__)} from to
from  - gsub from string or ruby script
to    - gsub to string or ruby script

example:
git gsub hoge piyo
git gsub '/hoge([0-9]+)/' 'piyo\#{$1.to_i + 1}'
git gsub '"piyo\#{4 + 1}"' 'piyo\#{$1.to_i + 1}'
EOS

end
