module Jekyll
  module ChecksumFilter
    def checksum(input)
      File.size(input)
    end
  end
end

Liquid::Template.register_filter(Jekyll::ChecksumFilter)