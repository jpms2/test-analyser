class Correct_coverage_report

	def correct(path)
		corrected_lines = []
		lines = read_file("#{path}/covered_files.txt")
		lines.each do |line|
			if((/^app\/.*/.match line) || (/^lib\/.*/.match line))
				corrected_lines.push(line)
			end
		end
		corrected_lines = check(path, corrected_lines)
		write_on_file(ident(corrected_lines), "#{path}/covered_files.txt")
	end

	def check(path, lines)
		file_name_regex = /(\/)(?!.*\/).+/
		corrected_lines = []
		lines.each do |line|
			file_name = (file_name_regex.match(line)).to_s[1..-4]
			file_path = "#{path}/files/#{file_name}.txt"
			if (File.exist?(file_path))
				file_lines = read_file(file_path)
				removable = true
				file_lines.each do |file_line|
					if(!( (/^\n$/.match(file_line)) || (/^ *require .*/.match(file_line)) || (/^ *module .*/.match(file_line)) || 
							(/^ *def .*/.match(file_line)) || (/^ *class .*/.match(file_line)) || (/^ *include .*/.match(file_line)) ||
						  (/^ *private.*/.match(file_line)) ))
						removable = false
					end
				end
				if(!removable)
					corrected_lines.push(line)
				end
			end
		end
		corrected_lines
	end

	def ident(array)
		text = '' 
		array.each do |element|
			text = text + element
		end
		text
	end

	def read_file(path)
    array_line = []
    File.foreach(path) do |line|
      array_line.push line
    end
    array_line
  end

	def write_on_file(text, path)
    File.open("#{path}", 'w') do |f|
      f.write text
    end
  end

end

#Correct_coverage_report.new.correct("/home/ess/test-analyser/results/all/result_whitehall/73")
