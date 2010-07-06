namespace :git do
  desc "Switches all readonly urls in .git/config to write"
  task :write do
    if File.exists?(".git/config")
      config = File.read(".git/config")
      new_config = config.split("\n").collect{ |line|
        if line =~ /(.*)\:\/\/(.*)\/(.*)\/(.*)\.git/
          line = "#{$1}@#{$2}:#{$3}/#{$4}.git"
        end
        line
      }.join("\n")
      config = File.open(".git/config", "w")
      config.write(new_config)
    else
      puts "No .git/config found"
    end
  end
  namespace :modules do
    desc "Switches all write urls in .gitmodules to readonly"
    task :read do
      if File.exists?(".gitmodules")
        modules = File.read(".gitmodules")
        new_modules = modules.split("\n").collect{ |line|
          if line =~ /(\W)+url = (.*)@(.*):(.*)\/(.*)\.git/
            line = "#{$1}url = #{$2}://#{$3}/#{$4}/#{$5}.git"
          end
          line
        }.join("\n")
        modules = File.open(".gitmodules", "w")
        modules.write(new_modules)
      else
        puts "No .gitmodules found"
      end
    end
  end
end
