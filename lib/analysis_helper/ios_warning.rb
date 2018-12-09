module AnalysisHelper
  class IOSWarning
    attr_reader :file
    attr_reader :line
    attr_reader :row
    attr_reader :content
    attr_reader :origin

    def initialize(origin)
      @origin = origin
      strs = origin.split(':', 4)
      @file = strs[0]
      @line = strs[1].to_i
      @row = strs[2].to_i
      @content = strs[3]
    end

    def <=>(other)
      if @file != other.file
        return @file <=> other.file
      end
      if @line != other.line
        return @line <=> other.line
      end
      if @row != other.row
        return @row <=> other.row
      end
      @origin <=> other.origin
    end
  end
end