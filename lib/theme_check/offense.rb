# frozen_string_literal: true
module ThemeCheck
  class Offense
    include PositionHelper

    MAX_SOURCE_EXCERPT_SIZE = 120

    attr_reader :check, :message, :template, :node, :markup, :line_number, :correction

    def initialize(
      check:, # instance of a ThemeCheck::Check
      message: nil, # error message for the offense
      template: nil, # Template
      node: nil, # Node or HtmlNode
      markup: nil, # string
      line_number: nil, # line number of the error (1-indexed)
      # node_markup_offset is the index inside node.markup to start
      # looking for markup :mindblow:.
      # This is so we can accurately highlight node substrings.
      # e.g. if we have the following scenario in which we
      # want to highlight the middle comma
      #   * node.markup == "replace ',',', '"
      #   * markup == ","
      # Then we need some way of telling our Position class to start
      # looking for the second comma. This is done with node_markup_offset.
      # More context can be found in #376.
      node_markup_offset: 0,
      correction: nil # block
    )
      @check = check
      @correction = correction

      if message
        @message = message
      elsif defined?(check.class::MESSAGE)
        @message = check.class::MESSAGE
      else
        raise ArgumentError, "message required"
      end

      @node = node
      @template = nil
      if node
        @template = node.template
      elsif template
        @template = template
      end

      @markup = if markup
        markup
      else
        node&.markup
      end

      raise ArgumentError, "Offense markup cannot be an empty string" if @markup.is_a?(String) && @markup.empty?

      @line_number = if line_number
        line_number
      elsif @node
        @node.line_number
      end

      @position = Position.new(
        @markup,
        @template&.source,
        line_number_1_indexed: @line_number,
        node_markup_offset: node_markup_offset,
        node_markup: node&.markup
      )
    end

    def source_excerpt
      return unless line_number
      @source_excerpt ||= begin
        excerpt = template.source_excerpt(line_number)
        if excerpt.size > MAX_SOURCE_EXCERPT_SIZE
          excerpt[0, MAX_SOURCE_EXCERPT_SIZE - 3] + '...'
        else
          excerpt
        end
      end
    end

    def start_index
      @position.start_index
    end

    def start_line
      @position.start_row
    end

    def start_column
      @position.start_column
    end

    def end_index
      @position.end_index
    end

    def end_line
      @position.end_row
    end

    def end_column
      @position.end_column
    end

    def code_name
      check.code_name
    end

    def markup_start_in_excerpt
      source_excerpt.index(markup) if markup
    end

    def severity
      check.severity
    end

    def check_name
      StringHelpers.demodulize(check.class.name)
    end

    def doc
      check.doc
    end

    def location
      tokens = [template&.relative_path, line_number].compact
      tokens.join(":") if tokens.any?
    end

    def location_range
      tokens = [template&.relative_path, start_index, end_index].compact
      tokens.join(":") if tokens.any?
    end

    def correctable?
      !!correction
    end

    def correct
      if correctable?
        corrector = Corrector.new(template: template)
        correction.call(corrector)
      end
    end

    def whole_theme?
      check.whole_theme?
    end

    def single_file?
      check.single_file?
    end

    def ==(other)
      other.is_a?(Offense) &&
        code_name == other.code_name &&
        message == other.message &&
        location == other.location &&
        start_index == other.start_index &&
        end_index == other.end_index
    end
    alias_method :eql?, :==

    def to_s
      if template
        "#{message} at #{location}"
      else
        message
      end
    end

    def to_s_range
      if template
        "#{message} at #{location_range}"
      else
        message
      end
    end
  end
end
