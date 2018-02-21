class Read
  require 'spreadsheet'
  require './Model'
  require_relative 'Return_coverage_reports'

  def read_from_ss(ss_path)
    model_array  = []
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet.open ss_path
    sheet_type = ""
    if ((/-.*/.match ss_path).to_s).include?"all"
      sheet_type = "all"
    end
    if ((/-.*/.match ss_path).to_s).include?"added"
      sheet_type = "added"
    end
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
      if row[5].to_s.include?('coveralls') || row[5].to_s.include?('simplecov')
        all_tests = row[6].scan /[^;]*/
      else
        all_tests = row[5].to_s.scan /[^;]*/
      end
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
    [model_array, github_url,sheet_type]
  end

  def call_script(ss_path)
    modelsAndUrl = read_from_ss(ss_path)
    model_array = modelsAndUrl[0]
    model_array.each do |model|
      puts model.test_dir.length
      git_url = "#{modelsAndUrl[1].to_s}"
      ruby_v = "#{model.ruby_v.to_s}"
      task_num = "#{model.task_num.to_s}"
      rails_v =  "#{model.rails_v.to_s}"
      tests =  "#{model.tests.to_s}"
      index = 0
      system("#{__dir__}/script_clone_checkout.sh", git_url, task_num)
      model.test_dir.each do |test_dir|
        check = index - 1
        while test_dir == model.test_dir[check] && check != -1
          model.test_line[index] += 1
          check -= 1
        end
        update_file_by_line(test_dir, model.test_line[index])
        index += 1
      end
      rep_name = (/[^\/]*$/.match(git_url)).to_s[0..-5]
      if rep_name == "diaspora" || rep_name == "wpcc" || rep_name == "one-click-orgs" || rep_name == "tip4commit" || rep_name == "whitehall"
        update_gemfile("#{__dir__}/#{rep_name}/Gemfile")
      end
      update_config_files(rep_name)
      update_cov_config_file("#{__dir__}/#{rep_name}/features/support/env.rb")
      worked = system("#{__dir__}/script.sh", git_url, task_num,ruby_v,rails_v,tests)
      sheet_type = modelsAndUrl[2]
      index_dir = "#{__dir__}/#{rep_name}/coverage/index.html"
      Return_coverage_reports.new.save_covered_files(index_dir, model.task.to_s,rep_name, sheet_type)
    end
  end

  def update_file_by_line(path, line_num)
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
      updated_file.push file_lines[file_lines.length - 1]
      index = 0
      idented_updated_file = ""
      while index < updated_file.length
        idented_updated_file = idented_updated_file + updated_file[index]
        index += 1
      end
      write_on_file(idented_updated_file, path)
  end

  def update_config_files(rep_name)
    config_path = "#{__dir__}/#{rep_name}/config/config.yml.sample"
    app_path = "#{__dir__}/#{rep_name}/config/application.yml.sample"
    database_path = "#{__dir__}/#{rep_name}/config/database.yml.sample"
    database_path2 = "#{__dir__}/#{rep_name}/config/database.yml.tmpl"
    database_path3 = "#{__dir__}/#{rep_name}/config/database.yml.example"
    database_path4 = "#{__dir__}/#{rep_name}/config/database.travis.yml"
    database_path5 = "#{__dir__}/#{rep_name}/config/_database.yml"
    site_path = "#{__dir__}/#{rep_name}/config/site.yml.tmpl"
    diaspora_path = "#{__dir__}/#{rep_name}/config/diaspora.yml.example"
    redis_path = "#{__dir__}/#{rep_name}/config/redis-cucumber.conf.example"
    redis_conf_path = "#{__dir__}/#{rep_name}/config/redis.travis.example"
    redis_path2 = "#{__dir__}/#{rep_name}/config/redis.example"

    if File.file? config_path
      File.rename(config_path, config_path[0..-8])
    end
    if File.file? app_path
      File.rename(app_path, app_path[0..-8])
    end
    if File.file? database_path
      File.rename(database_path, database_path[0..-8])
    end
    if File.file? database_path2
      File.rename(database_path2, database_path2[0..-6])
    end
    if File.file? database_path3
      File.rename(database_path3, database_path3[0..-9])
    end
    if File.file? database_path4
      File.rename(database_path4, "#{database_path3[0..-11]}ml")
    end
    if File.file? database_path5
      File.rename(database_path5, "#{__dir__}/#{rep_name}/config/database.yml")
    end
    if File.file? site_path
      File.rename(site_path, site_path[0..-6])
    end
    if File.file? diaspora_path
      File.rename(diaspora_path, diaspora_path[0..-9])
    end
    if File.file? redis_path
      File.rename(redis_path, redis_path[0..-9])
    end
    if File.file? redis_conf_path
      File.rename(redis_conf_path, "#{redis_conf_path[0..-16]}.conf")
    end
    if File.file? redis_path2
      File.rename(redis_path2, "#{__dir__}/#{rep_name}/config/redis.yml")
    end
  end

    def update_gemfile(path)
    file_lines = read_file(path)
    updated_file = []
    index = 0
    while index < file_lines.length
     if (file_lines[index].include?("  gem \"pg\",     \"0.18.4\"")) && (file_lines[2].include?("gem \"rails\", \"4.2.5.1\""))
        updated_file.pop
        updated_file.push("gem \"pg\"\n")
        updated_file.push("gem 'rake', '< 11'\n")
        index += 2
      end

      if file_lines[index].include?("gem \"rails\", \"4.2.5\"")
        updated_file.push(file_lines[index])
        updated_file.push("gem \"pg\"\n")
        updated_file.push("gem 'rake', '< 11'\n")
      else
        if file_lines[index].include?("  gem \"pg\",     \"0.18.4\"")
          updated_file.pop
          index += 2
        else
         if file_lines[index].include? "http://gems.dev.mas.local"
         	updated_file.push("gem 'dough-ruby', path: '/home/ess/test-analyser/dough'\n")
         else
					if	file_lines[index].include? "gem 'debugger'"
						updated_file.push("\n")
					else
						if file_lines[index].include?("gem \"simplecov\", :platforms => :ruby_19")
						updated_file.push("  gem \"simplecov\"\n")
						else
							if file_lines[index].include?("gem 'unicorn', '4.6.2'")
								updated_file.push("#gem 'unicorn', '4.6.2'\n")
							else
								if file_lines[index].include?("gem 'raindrops', '0.11.0'")
									updated_file.push("#gem 'raindrops', '0.11.0'\n")
								else
									updated_file.push(file_lines[index])
								end
							end
						end
					end
         end
        end
      end
      index += 1
    end
    i = 0
    idented_updated_file = ""
    while i < updated_file.length
      idented_updated_file = idented_updated_file + updated_file[i]
      i += 1
    end
    write_on_file(idented_updated_file, path)
  end

  def update_cov_config_file(path)
    file_lines = read_file(path)
    updated_file = []
    index = 0
    updated = false
    while index < file_lines.length
      if (file_lines[index].include?("require 'coveralls'") && !updated)
	updated_file.push("require 'simplecov'\n")
        updated_file.push("SimpleCov.start\n")
	updated = true
      else
        if !file_lines[index].include?("Coveralls.wear_merged!")
          if ((file_lines[index].include?("require 'cucumber/rails'")) || file_lines[index].include?("require \"cucumber/rails\"")) && (!file_lines[index + 1].include?("require 'simplecov'") && !updated)
            updated_file.push(file_lines[index])
            updated_file.push("require 'simplecov'\n")
            updated_file.push("SimpleCov.start\n")
          else
            updated_file.push(file_lines[index])
          end
        end
      end
      index += 1
    end
    i = 0
    idented_updated_file = ""
    while i < updated_file.length
      idented_updated_file = idented_updated_file + updated_file[i]
      i += 1
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

Read.new.call_script('/home/ess/planilhas/cypress-tests-all.xls')
#Read.new.update_cov_config_file('C:/Users/jpms2/Desktop/testFile')
