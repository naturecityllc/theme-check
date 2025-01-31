# frozen_string_literal: true
require 'json'

module ThemeCheck
  class JsonPrinter
    def print(offenses)
      json = offenses_by_path(offenses)
      puts JSON.dump(json)
    end

    def offenses_by_path(offenses)
      offenses
        .map(&:to_h)
        .group_by { |offense| offense[:path] }
        .map do |(path, path_offenses)|
          {
            path: path,
            offenses: path_offenses.map { |offense| offense.filter { |k, _v| k != :path } },
            errorCount: path_offenses.count { |offense| offense[:severity] == Check::SEVERITY_VALUES[:error] },
            suggestionCount: path_offenses.count { |offense| offense[:severity] == Check::SEVERITY_VALUES[:suggestion] },
            styleCount: path_offenses.count { |offense| offense[:severity] == Check::SEVERITY_VALUES[:style] },
          }
        end
    end
  end
end
