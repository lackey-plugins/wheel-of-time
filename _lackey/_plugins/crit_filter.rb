module Jekyll
  module CritFilter
    def crit(input)
    	res = []
    	input.each { |key, value|
    		ev, field, data = nil, nil, nil

    		case key
    		when "=="
    			ev = "<eval>IS</eval>"
    			field = "<field>#{value[0]["var"]}</field>"
    			data = "<data>#{value[1]}</data>"
    		when "!"
    			if value.key? "in"
    				ev = "<eval>DOESNTCONTAIN</eval>"
    				field = "<field>#{value[1]["var"]}</field>"
    				data = "<data>#{value[0]}</data>"
    			end
    		when "in"
    			ev = "<eval>CONTAINS</eval>"
    			field = "<field>#{value[1]["var"]}</field>"
    			data = "<data>#{value[0]}</data>"
    		when ">"
    			ev = "<eval>ISGREATERTHAN</eval>"
    			field = "<field>#{value[0]["var"]}</field>"
    			data = "<data>#{value[1]}</data>"
    		when "<"
    			ev = "<eval>ISLESSTHAN</eval>"
    			field = "<field>#{value[0]["var"]}</field>"
    			data = "<data>#{value[1]}</data>"
    		end

    		unless ev.nil? and field.nil? and data.nil?
    			res.append("#{field}#{ev}#{data}")
    		end
    	}
    	res
    end

  end
end

Liquid::Template.register_filter(Jekyll::CritFilter)