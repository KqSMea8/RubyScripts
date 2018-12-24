if $PROGRAM_NAME == __FILE__
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end
require 'analysis_helper/ios_warning'

module AnalysisHelper
  class Filter
    def is_high_priority_warning(item)
      l = item.origin
      if !%w(.h .m).include?(File.extname(item.file))
        false
      elsif l.include?('never read')
        false
      elsif l.include?('[(super or self) init')
        true
      elsif l.include?('is missing a [super')
        true
      elsif l.include?('cannot be nil')
        true
      elsif l.include?('non-null')
        false
      elsif l.include?('uninitialized when captured by block')
        true
      elsif l.include?('to a scalar')
        true
      elsif l.include?('ull pointer')
        true
      elsif l.include?('non-void')
        false
      elsif l.include?('Potential leak of')
        false
      elsif l.include?('Conversion from value')
        true
      elsif l.include?('Converting a pointer value')
        true
      elsif l.include?('has \'copy\' attribute')
        true
      elsif l.include?('zero-allocated')
        false
      elsif l.include?('autoreleasing out parameter')
        true
      elsif l.include?('Null pointer argument in call to memory set function')
        false
      elsif l.include?('null dereference')
        true
      elsif l.include?('contains uninitialized data')
        true
      elsif l.include?('garbage')
        true
      elsif l.include?('dangerous')
        true
      else
        false
      end
    end

    def filter(file_in, file_analysis_out, file_warning_out)
      is_analyze_warning = false
      analysis = Array.new
      warnings = Array.new

      high_priority_count = 0
      low_priority_count = 0

      while (line = file_in.gets)
        if line.start_with?('Analyze')
          is_analyze_warning = true
        elsif line.start_with?('Compile')
          is_analyze_warning = false
        elsif line.start_with?('ld:')
          # do nothing
        elsif line.start_with?('libpng')
          # do nothing
        else
          if line.include?(' warning: ')
            l = line.sub(/\/Users\/nami\/git\/tt_app_ios\d?\//, '')
            item = IOSWarning.new(l)
            is_high_priority = is_analyze_warning && is_high_priority_warning(item)

            array = is_analyze_warning ? analysis : warnings
            array << item

            if is_high_priority
              high_priority_count += 1
            elsif is_analyze_warning
              low_priority_count += 1
            end
          end
        end
      end
      puts "Read log OK."
      analysis.sort!
      last_item = IOSWarning.new("")
      analysis.each do |i|
        if i.origin != last_item.origin
          file_analysis_out.puts(i.origin)
          last_item = i
        end
      end
      file_analysis_out.flush
      file_analysis_out.close
      puts "Get Analysis OK."
      warnings.sort!
      last_item = IOSWarning.new("")
      warnings.each do |i|
        if i.origin != last_item.origin
          file_warning_out.puts(i.origin)
          last_item = i
        end
      end
      file_warning_out.flush
      file_warning_out.close
      puts "Get Warnings OK."

      puts "Success: 完成 高优数：#{high_priority_count}，普优数：#{low_priority_count}"
    end
  end

  def AnalysisHelper.filter(in_file_path, analysis_out_path, waring_out_path)
    filter = Filter.new
    filter.filter(File.new(in_file_path, File::RDONLY), File.new(analysis_out_path, File::WRONLY | File::CREAT), File.new(waring_out_path, File::WRONLY | File::CREAT))
  end
  #
  # file_in_path = ARGV.first
  # unless file_in_path
  #   puts "Usage: analysis_filter log_file [analysis_file] [warning_file]"
  #   exit(-1)
  # end
  #
  # file_analysis_out_path = ARGV.at(1)
  #
  # unless file_analysis_out_path
  #   # file_analysis_out_path = File.basename(file_in_path, '.*') + '_analysis.txt'
  #   file_analysis_out_path = '/Users/nami/git/TTStaticAnalyzeLog/NewsInHouse_analysis.txt'
  # end
  #
  # file_warning_out_path = ARGV.at(2)
  #
  # unless file_warning_out_path
  #   # file_warning_out_path = File.basename(file_in_path, '.*') + '_warning.txt'
  #   file_warning_out_path = '/Users/nami/git/TTStaticAnalyzeLog/NewsInHouse_warning.txt'
  # end
end