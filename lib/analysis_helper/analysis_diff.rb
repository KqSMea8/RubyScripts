if $PROGRAM_NAME == __FILE__
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end
require 'analysis_helper/ios_warning'
require 'analysis_helper/array_differ'

module AnalysisHelper
  class Differ
    attr :array_left
    attr :array_right
    attr :file_out
    attr :left_index
    attr :right_index
    attr :adds
    attr :subs

    def initialize(file_left, file_right, file_out)
      @array_left = load_ios_warnings(file_left)
      @array_right = load_ios_warnings(file_right)
      @file_out = file_out
    end

    def load_ios_warnings(file_in)
      array = Array.new
      while (line = file_in.gets)
        item = IOSWarning.new(line)
        array << item
      end
      array
    end

    def puts_add_item(item)
      # @file_out.puts "+ #{item.origin}"
      adds << item
    end

    def puts_sub_item(item)
      # @file_out.puts "- #{item.origin}"
      subs << item
    end

    def diff_same_file_items(left_items, right_items)
      left_contents = left_items.map(&:content)
      right_contents = right_items.map(&:content)
      diff = Diff.new(left_contents, right_contents)
      diff.diffs.each do |x|
        x.each do |mod|
          if mod[0] == "-"
            puts_sub_item(left_items[mod[1]])
          elsif mod[0] == "+"
            puts_add_item(right_items[mod[1]])
          else
            STDERR.puts "Error"
            exit 1
          end
        end
      end
    end

    def diff_next_file()
      if @left_index < @array_left.length && @right_index < @array_right.length
        if @array_left[@left_index].file < @array_right[@right_index].file
          file = @array_left[@left_index].file
          while @left_index < @array_left.length && file == @array_left[@left_index].file
            puts_sub_item(@array_left[@left_index])
            @left_index += 1
          end
        elsif @array_left[@left_index].file > @array_right[@right_index].file
          file = @array_right[@right_index].file
          while @right_index < @array_right.length && file == @array_right[@right_index].file
            puts_add_item(@array_right[@right_index])
            @right_index += 1
          end
        else
          file = @array_left[@left_index].file
          left_items = Array.new
          right_items = Array.new
          while @left_index < @array_left.length && file == @array_left[@left_index].file
            left_items << @array_left[@left_index]
            @left_index += 1
          end
          while @right_index < @array_right.length && file == @array_right[@right_index].file
            right_items << @array_right[@right_index]
            @right_index += 1
          end
          diff_same_file_items(left_items, right_items)
        end
      else
        while @left_index < @array_left.length
          puts_sub_item(@array_left[@left_index])
          @left_index += 1
        end
        while @right_index < @array_right.length
          puts_add_item(@array_right[@right_index])
          @right_index += 1
        end
      end
    end

    def go()
      @left_index = 0
      @right_index = 0
      @adds = Array.new
      @subs = Array.new
      while @left_index < @array_left.length || @right_index < @array_right.length
        diff_next_file
      end

      @file_out.puts "=================== 增加 #{@adds.length} ===================="
      @adds.each do |x|
        @file_out.puts x.origin
      end
      @file_out.puts "=================== 减少 #{@subs.length} ===================="
      @subs.each do |x|
        @file_out.puts x.origin
      end
    end
  end

  def AnalysisHelper.diff(left_file_path, right_file_path, out_file_path)
    diff = Differ.new(File.new(left_file_path, File::RDONLY), File.new(right_file_path, File::RDONLY), File.new(out_file_path, File::WRONLY | File::CREAT))
    diff.go
  end
end