
class Return_coverage_reports

  def save_covered_files(file_path, action_hash, repository_name, sheet_type)
    covered_files = get_covered_classes(file_path)
    indented_output = ''
    covered_files.each do |covered_file|
      indented_output = indented_output + "#{covered_file}\n"
    end

    folder = ""
    if sheet_type == "all"
      create_folder("#{__dir__}/results")
      create_folder("#{__dir__}/results/all")
      create_folder("#{__dir__}/results/all/result_#{repository_name}/")
      create_folder("#{__dir__}/results/all/result_#{repository_name}/#{action_hash}")
      path = "#{__dir__}/results/all/result_#{repository_name}/#{action_hash}/covered_files"
      folder = "all"
    else
      create_folder("#{__dir__}/results")
      create_folder("#{__dir__}/results/added")
      create_folder("#{__dir__}/results/added/result_#{repository_name}/")
      create_folder("#{__dir__}/results/added/result_#{repository_name}/#{action_hash}")
      path = "#{__dir__}/results/added/result_#{repository_name}/#{action_hash}/covered_files"
      folder = "added"
    end
    write_on_file(indented_output,path)
    get_covered_lines(file_path, covered_files, action_hash, repository_name, folder)
  end

  def get_covered_classes(file_path)
    full_file = read_file(file_path)
    index = 0
    possible_file_name_regex = /<td.*>.*<\/td>/
    percentage_regex = /<td.*>.*%<\/td>/
    value_from_percentage = />([^>]+)%/
    file_name_regex = /title="([^>]+)">/
    output_array = []

    while index <= full_file.length
      line = full_file[index]
      next_line = full_file[index + 1]
      if line =~ possible_file_name_regex && next_line =~ percentage_regex
        if (value_from_percentage.match(next_line).to_s)[1..-1].delete(' ') != '0.0%'
          output_array.push(file_name_regex.match(line).to_s[7..-3])
        end
      end
      index += 1
    end
  output_array.uniq
  end

  def get_covered_lines(file_path, covered_files, action_hash, repository_name, folder)
    line_hit_regex = /class="hits.+\n.+\n.+/
    ruby_with_html_regex = /ruby">.*</
    file_number = 0
    raw_lines_array = get_raw_covered_lines(file_path, covered_files)
    raw_lines_array.each do |raw_lines|
      hit_lines = []
      regex_scanned_lines = (raw_lines.join('')).scan(line_hit_regex)
      regex_scanned_lines.each do |hit_line|
        hit_lines.push (hit_line.match(ruby_with_html_regex).to_s)[6..-2]
      end
      indented_output = ""
      hit_lines.each do |hit_line|
        indented_output = indented_output + "#{hit_line}\n"
      end
      if file_number < covered_files.length
        file_name = (covered_files[file_number].match(/(\/)(?!.*\/).+/).to_s)[1..-4]
        path = "#{__dir__}/results/#{folder}/result_#{repository_name}/#{action_hash}/files/#{file_name}"
        create_folder("#{__dir__}/results/#{folder}/result_#{repository_name}/#{action_hash}/files")
        write_on_file(indented_output,path)
      end
      file_number += 1
    end
  end

  def get_raw_covered_lines(file_path, covered_files)
    output_array = []
    file = read_file(file_path)
    cf_index = 0
    code_start = 0
    file_index = 0
    while file_index <= file.length
      if file[file_index].to_s.include? "<h3>#{covered_files[cf_index]}</h3>"
        if code_start != 0
          covered_lines_html = file.slice(code_start, (file_index - code_start))
          output_array.push(covered_lines_html)
        end
          code_start = file_index
          cf_index += 1
      else
        if file[file_index].to_s.include? "<h3>"
          if code_start != 0
            covered_lines_html = file.slice(code_start, (file_index - code_start))
            output_array.push(covered_lines_html)
            code_start = 0
          end
        end
      end
      file_index += 1
    end
    output_array
  end

  def write_on_file(text, path)
    text_array = text.split("\n")
    array_line = []
    text_array.each do |line|
      r_line = line.gsub(/&gt;/,">")
      r_line = r_line.gsub(/&lt;/,"<")
      r_line = r_line.gsub(/&#39;/,"'")
      r_line = r_line.gsub(/&quot;/,"\"")
      r_line = r_line.gsub(/&amp;/,"&")
      array_line.push(r_line)
    end
    formated_text = ""
    i = 0
    while i < array_line.length
      formated_text = formated_text + "\n#{array_line[i]}"
      i+= 1
    end
    File.open("#{path}.txt", 'w') do |f|
      f.write formated_text
    end
  end

  def create_folder(path)
    Dir.mkdir(path) unless File.exists?(path)
  end

  def read_file(path)
    array_line = []
    File.foreach(path) do |line|
      array_line.push line
    end
  array_line
  end
end

#Return_coverage_reports.new.save_covered_files("//home//ess//test-analyser//solar//coverage//index.html", "68b36f7d04ba52402a51bf0dca94c06310d62287", "solar", "all")
