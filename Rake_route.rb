class Rake_route

	def get(path, task, sha, project)
		Dir.chdir path.to_s
		#system("git stash")
		#system("git checkout #{sha}")
		#system("bundle install")
		#system("RAILS_ENV=test bundle exec rake db:drop")
		#system("RAILS_ENV=test bundle exec rake db:setup")
		#system("RAILS_ENV=test bundle exec rake db:migrate")
  
		system("rvm use 2.0.0")
		route = %x( rake routes)
		write_on_file(route, path, task, project)
	end

	def write_on_file(text, path, task, project)
		File.open("/home/ess/test-analyser/routes/#{project}/#{task}.txt", "w") do |f|     
  		f.write(text)
		end
  end

end

Rake_route.new.get("/home/ess/test-analyser/LocalSupport", "1118", "7e9a88573b3762861ea1a39196a1606ee020050d" , "LocalSupport")
