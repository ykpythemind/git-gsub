#!/usr/bin/env ruby

begin
  raise "Invalid argument" if ARGV.size != 2 and ARGV.size != 3

  from_str, to_str, file_mask_str = ARGV
  begin
    from = eval(from_str)
  rescue
    from = from_str
  end

  file_mask = nil
  begin
    if file_mask_str
      file_mask = eval(file_mask_str)
    end
  rescue
    file_mask = file_mask_str
  end

  print "from:"
  p from: from, to: to_str, file_mask: file_mask

  files = `git ls-files`
  files.lines.each do |path|
    path.strip!
    if file_mask
      unless path.index file_mask
        next
      end
    end

    buf = nil
    open(path) do |f|
      old_buf = f.read
      begin
        p path: path, eval: "old_buf.gsub(from, \"#{to_str}\")"
        buf = old_buf.gsub(from) { eval(to_str) }
        buf = nil if old_buf == buf
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
ruby #{File.basename(__FILE__)} from to [file_mask]
from      - gsub from string or ruby script
to        - gsub to string or ruby script
file_mask - File name or file name matching ruby script

example:
git gsub hoge piyo
git gsub '/hoge([0-9]+)/' 'piyo\#{$1.to_i + 1}'
git gsub '"piyo\#{4 + 1}"' 'piyo\#{$1.to_i + 1}'
EOS

end
