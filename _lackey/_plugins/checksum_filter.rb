module Jekyll
  module ChecksumFilter
    def checksum(input)
      sum = Integer(-1)
      File.open(input, "rb").read.unpack("c*").each { |char| sum += char if char != 10 and char != 13 }
      sum
    end
  end
end

Liquid::Template.register_filter(Jekyll::ChecksumFilter)