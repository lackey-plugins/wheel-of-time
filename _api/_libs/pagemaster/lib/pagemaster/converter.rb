module Pagemaster
  class Converter < Jekyll::Converter
    safe true
    priority :low

    def matches(ext)
      ext =~ /^\.pagemaster$/i
    end

    def output_ext(ext)
      ""
    end

    def convert(content)
      content
    end
  end
end
