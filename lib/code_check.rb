#!/usr/bin/ruby
# -*- coding: UTF-8 -*-

class String
  def safe_path
    File.expand_path(self)
  end
end

class DidEndDisplayingCellAnalyzer

  def analyze(file_path)
    @file_path = file_path
    file = File.new(@file_path.safe_path, "r:UTF-8")
    @in_end_displaying_method = false
    @in_comments = false
    @line_code = 1
    file.each_line do |line|
      @line_row = 1
      filter_comments(line)
      @line_code += 1
    end
    file.close
  end

  def filter_comments(line)
    if @in_comments
      analyze_comments(line)
      return
    end
    if (index_of_quick_comment = line.index('//'))
      line = line[0..index_of_quick_comment]
    end
    if (index_of_comments = line.index('/*'))
      left_line = line[0..index_of_comments]
      analyze_method(left_line)
      right_line = line[(index_of_comments + 2)..line.length]
      @in_comments = true
      @line_row += index_of_comments + 2
      analyze_comments(right_line)
    else
      analyze_method(line)
    end
  end

  def analyze_comments(line)
    if (index_of_end_comments = line.index('*/'))
      right_line = line[(index_of_end_comments + 2)..line.length]
      @in_comments = false
      @line_row += index_of_end_comments + 2
      filter_comments(right_line)
    end
  end

  def analyze_method(line)
    if @in_end_displaying_method
      analyze_end_displaying_method(line)
      return
    end
    # if @method_line
    #   @method_line << " " << line
    #   if @method_line.include?("{")
    #     line = @method_line
    #     @method_line = nil
    #   else
    #     return
    #   end
    # elsif line.start_with?('-')
    #   @method_line = line
    # end
    if line =~ /-\s*\(void\)tableView:\(\w+\s*\*?\)\w+\s+didEndDisplayingCell:\(\w+\s*\*?\)\w+\s+forRowAtIndexPath:\(\w+\s*\*?\)(\w+)/
      @in_end_displaying_method = true
      @index_path_name = $1
      @parenthese_level = line.count('{')
    elsif line =~ /-\s*\(void\)collectionView:\(\w+\s*\*?\)\w+\s+didEndDisplayingCell:\(\w+\s*\*?\)\w+\s+forItemAtIndexPath:\(\w+\s*\*?\)(\w+)/
      @in_end_displaying_method = true
      @index_path_name = $1
      @parenthese_level = line.count('{')
    end
  end

  def analyze_end_displaying_method(line)
    @parenthese_level += line.count('{')
    @parenthese_level -= line.count('}')
    if @parenthese_level <= 0
      @in_end_displaying_method = false
    else
      if !@index_path_name.include?("unsafe") && (error_row = line.index(@index_path_name))
        STDERR.print("#{Dir.pwd}/#{@file_path}:#{@line_code}:#{error_row + @line_row}: error: Use unsafe indexPath! See: https://wiki.bytedance.net/pages/viewpage.action?pageId=279173422 \n")
        exit(1)
      end
    end
  end
end

# if $PROGRAM_NAME == __FILE__
#   ARGV.each do |file_path|
#     analyzer = DidEndDisplayingCellAnalyzer.new(file_path)
#     analyzer.analyze
#   end
# end

def analyze_file(file_path_line)
  if file_path_line.start_with?(' M ') || file_path_line.start_with?(' A ')
    file_path = file_path_line[3...file_path_line.length].strip
    extname = File.extname(file_path)
    if extname == '.m' || extname == '.mm'
      analyzer = DidEndDisplayingCellAnalyzer.new
      analyzer.analyze(file_path)
    end
  end
end

def analyze_main_project_files
  files = `git status -s`
  files.each_line(&method(:analyze_file))
end

def analyze_dev_pod_files
  unless File.exist?('Podfile.lock')
    return
  end
  podfile_lock = File.new('Podfile.lock', File::RDONLY)
  is_in_external_sources = false
  podfile_lock.each_line do |line|
    line = line.strip
    if line == 'EXTERNAL SOURCES:'
      is_in_external_sources = true
    elsif line == ''
      is_in_external_sources = false
    else
      if is_in_external_sources
        if (index = line.index(':path:'))
          path = line[(index + ':path: '.length)...line.length]
          unless path.start_with?('../Vendor')
            if Dir.exist?(path.safe_path)
              Dir.chdir(path.safe_path)
              files = `git status -s`
              files.each_line(&method(:analyze_file))
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root_path = ARGV.first
  if root_path
    Dir.chdir(root_path.safe_path)
  end

  begin
    analyze_main_project_files
    analyze_dev_pod_files
  rescue
    puts("error:#{$!} at:#{$@}")
  end
end