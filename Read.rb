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
      worked = system("#{__dir__}/script.sh", git_url, task_num,ruby_v,rails_v,tests)
      rep_name = (/[^\/]*$/.match(git_url)).to_s[0..-5]
      Return_coverage_reports.new.save_covered_files("#{__dir__}/#{rep_name}/coverage/index.html", model.task.to_s)
    end
  end

end

Read.new.call_script('/home/ess/planilhas/TheOdinProject_theodinproject-tests.xls')
