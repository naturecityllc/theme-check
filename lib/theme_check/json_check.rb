# frozen_string_literal: true

module ThemeCheck
  class JsonCheck < Check
    extend ChecksTracking

    def add_offense(message, markup: nil, line_number: nil, template: nil, &block)
      offenses << Offense.new(check: self, message: message, markup: markup, line_number: line_number, template: template, correction: block)
    end
  end
end
