require "csv"

csv_text = File.read(ARGV[0]) 
original = CSV.parse(csv_text, {:col_sep => "\t", :quote_char => "\x00"})

CSV.open(ARGV[1], "wb", {:col_sep => "\t", :quote_char => "\x00"}) do |csv|
  indices = [1, 2, 0] + (3 ... original.to_a[0].length).to_a
  header_row = true
  columns = ["ImageFile", "Name", "Set"].to_a
  original.to_a.each do |row|
    csv << indices.map { |index|
      if header_row
        if index < columns.length
          columns[index]
        else
          row[index]
        end
      else
        row[index]
      end
    }
    header_row = false
  end
end