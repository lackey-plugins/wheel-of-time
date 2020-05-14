require 'json'

module Jekyll
  module JsonFilter
    def json(input)
      JSON.parse(input.gsub(/'/, '"'))
    end
  end
end

Liquid::Template.register_filter(Jekyll::JsonFilter)