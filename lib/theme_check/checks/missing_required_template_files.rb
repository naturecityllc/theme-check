# frozen_string_literal: true

module ThemeCheck
  # Reports missing shopify required theme files
  # required templates: https://shopify.dev/tutorials/review-theme-store-requirements-files
  class MissingRequiredTemplateFiles < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    REQUIRED_LIQUID_FILES = %w(layout/theme)
    REQUIRED_TEMPLATE_FILES = %w(
      index product collection cart blog article page list-collections search 404
      gift_card customers/account customers/activate_account customers/addresses
      customers/login customers/order customers/register customers/reset_password password
    )
      .map { |file| "templates/#{file}" }

    def on_end
      (REQUIRED_LIQUID_FILES - theme.liquid.map(&:name)).each do |file|
        add_offense("'#{file}.liquid' is missing") do |corrector|
          corrector.create(@theme, "#{file}.liquid", "")
        end
      end
      (REQUIRED_TEMPLATE_FILES - (theme.liquid + theme.json).map(&:name)).each do |file|
        add_offense("'#{file}.liquid' or '#{file}.json' is missing") do |corrector|
          (file == "templates/gift_card" || file.split("/")[1] == "customers") ? corrector.create(@theme, "#{file}.liquid", "") : corrector.create(@theme, "#{file}.json", "")
        end
      end
    end
  end
end
