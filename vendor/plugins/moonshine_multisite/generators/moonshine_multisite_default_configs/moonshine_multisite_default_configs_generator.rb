require File.dirname(__FILE__) + "/../../lib/multisite_helper.rb"

class MoonshineMultisiteDefaultConfigsGenerator < Rails::Generator::Base
  def manifest
    if ARGV.first == 'private'
      ARGV.shift
      generate_private = true
    end
    visibility = generate_private ? 'private' : 'public'

    STDOUT.print "Server filter (blank for all): "
    server_filter = STDIN.gets.chomp
    STDOUT.print "DB Host: " # TODO: put this in moonshine_multisite.yml
    db_host = STDIN.gets.chomp
    STDOUT.print "DB User: "
    db_user = STDIN.gets.chomp
    STDOUT.print "DB Password: "
    password = STDIN.gets.chomp

    record do |m|
      m.directory "app/manifests"
      m.directory "app/manifests/assets"
      m.directory "app/manifests/assets/#{visibility}"
      m.directory "app/manifests/assets/#{visibility}/database_configs"
      unless generate_private
        multisite_config_hash[:servers].each do |server, config|
          multisite_config_hash[:apps].keys.each do |app|
            multisite_config_hash[:stages].each do |stage|
              config[:db_names] ||= {}
              config[:db_names][app] ||= {}
              config[:db_names][app][stage] ||= "#{server}.#{app}.#{stage}"
            end
          end
        end
      end
      multisite_config_hash[:servers].each do |server, config|
        if server_filter != ''
          next unless server.to_s == server_filter
        end
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            utopian = "#{server}_#{app}_#{stage}"
            dest = "app/manifests/assets/#{visibility}/database_configs/database.#{utopian}.yml"
            if generate_private
              if config[:db_names] && config[:db_names][app] && config[:db_names][app][stage]
                database = config[:db_names][app][stage]
              else
                next
              end
            else
              database = utopian
            end
            m.template "database.yml.erb", dest, :assigns => { :database => database,
              :password => password, :server => server, :app => app, :stage => stage,
              :config => config, :multisite_config_hash => multisite_config_hash,
              :db_user => db_user, :db_host => db_host }
          end
        end
      end
    end
  end
end
