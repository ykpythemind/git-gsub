#!/usr/bin/env ruby

require "open3"
require "optparse"

def text_file?(filename)
  file_type, status = Open3.capture2e("file", filename)
  status.success? && file_type.include?("text")
end

begin
  opt = OptionParser.new
  option = false
  opt.on('-d', '--dry-run', 'dry run') { |v| option = v }
  opt.parse!(ARGV)
  raise "Invalid argument" if ARGV.size != 2 and ARGV.size != 3

  from_str, to, file_mask_str = ARGV
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

  begin
    eval(to)
    to_str = nil
  rescue => ex
    p ex
    to_str = to
  end

  print "from:"
  if to_str
    p from: from, to_str: to_str, file_mask: file_mask
  else
    p from: from, eval: to, file_mask: file_mask
  end

  files = `git ls-files`
  files.lines.each do |path|
    path.strip!
    if file_mask
      unless path.index file_mask
        next
      end
    end

    next unless text_file? path
    buf = nil
    open(path) do |f|
      old_buf = f.read
      begin
        if to_str
          buf = old_buf.gsub(from, to_str)
        else
          buf = old_buf.gsub(from) { eval(to) }
        end
        buf = nil if old_buf == buf
      rescue => ex
        puts "error:#{ex.inspect} on:#{path} backtrace:#{ex.backtrace}"
        next
      end
    end
    if buf
      puts "replaced:#{path}"
      unless option
        open(path, "w") do |f|
          f.write buf
        end
      else
        puts buf
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
