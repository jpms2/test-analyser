class Read
  require 'spreadsheet'
  require './Model'
  require_relative 'Return_coverage_reports'

  def read_from_ss(ss_path)
    model_array  = []
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet.open ss_path
    sheet = book.worksheet 0
    github_url = sheet.row(0)[1]
    project_name = (/([^\/]+)$/.match github_url).to_s[0...-4]
    sheet.each 2 do |row|
      model = Model.new
      model.task = row[0]
      model.task_num = row[1]
      model.ruby_v = row[2]
      model.rails_v = row[3]
      model.coveralls = row[4]
      all_tests = row[5].scan /[^;]*/
      index = 0
      model.test_dir = []
      model.test_line = []
      all_tests.each do |test|
        if test.to_s != ''
          line_num = /(?<=\().+?(?=\))/.match test
          line_content = /.*\(/.match test
          line = line_content.to_s[0...-1]
	  if model.tests.to_s != ''
	    model.tests = "#{model.tests}," + "#{line}:#{line_num}"
	    model.test_dir.push "#{__dir__}/#{project_name}/#{line}"
	    model.test_line.push Integer(line_num.to_s)
	  else
	    model.tests = "#{line}:#{line_num}"
	    model.test_dir.push "#{__dir__}/#{project_name}/#{line}"
	    model.test_line.push Integer(line_num.to_s)
	  end
        end
	index += 1
      end
      model_array.push(model)
    end
    [model_array, github_url]
  end

  def call_script(ss_path)
    modelsAndUrl = read_from_ss(ss_path)
    model_array = modelsAndUrl[0]
    model_array.each do |model|
      git_url = "#{modelsAndUrl[1].to_s}"
      ruby_v = "#{model.ruby_v.to_s}"
      task_num = "#{model.task_num.to_s}"
      rails_v =  "#{model.rails_v.to_s}"
      tests =  "#{model.tests.to_s}"
      index = 0
      system("#{__dir__}/script_clone_checkout.sh", git_url, task_num)
      model.test_dir.each do |test_dir|
      update_file(test_dir, model.test_line[index])
      index += 1
      end
      worked = system("#{__dir__}/script.sh", git_url, task_num,ruby_v,rails_v,tests)
      rep_name = (/[^\/]*$/.match(git_url)).to_s[0..-5]
      Return_coverage_reports.new.save_covered_files("#{__dir__}/#{rep_name}/coverage/index.html", model.task.to_s)
    end
  end

  def update_file(path, line_num)
      file_lines = read_file(path)
      updated_file = []
      i = 0
      updated = false
      while i < file_lines.length
        if updated
          updated_file.push file_lines[i - 1]
        else
          if i == line_num - 1 && !file_lines[i].include?('@cin_ufpe_tan')
            updated_file.push '@cin_ufpe_tan' + "\n"
            updated = true
          else
            updated_file.push file_lines[i]
          end
        end
        i += 1
      end
      index = 0
      idented_updated_file = ""
      while index < updated_file.length
        idented_updated_file = idented_updated_file + updated_file[index]
        index += 1
      end
      write_on_file(idented_updated_file, path)
  end

  def write_on_file(text, path)
    File.open("#{path}", 'w') do |f|
      f.write text
    end
  end

  def read_file(path)
    array_line = []
    File.foreach(path) do |line|
      array_line.push line
    end
    array_line
  end

end

Read.new.call_script('/home/ess/planilhas/tip4commit_tip4commit-tests.xls')
