require "#{File.dirname(__FILE__)}/multisite_helper.rb"

class DatabaseYml
  RAILS_ROOT = "#{File.dirname(__FILE__)}/../../../../" unless defined?(RAILS_ROOT)

  def self.database_yml
    unless defined?(Common) && defined?(Common::SERVER) && 
      defined?(Common::APP) && defined?(Common::STAGE)
      return %|
development:
  adapter: mysql
  database: rails_app
production:
  adapter: mysql
  database: rails_app
|
    end

    multisite_config_hash(false)
    yml = %|
#{ 
dbh = "#{RAILS_ROOT}/config/database/database_header.yml"; dbhd = dbh+".default";
file = File.exists?(dbh) ? dbh : dbhd
File.read(file).chomp
}

development:
  database: #{local_db_name(Common::SERVER, Common::APP, Common::STAGE)}
  <<: *defaults

production:
  database: #{local_db_name(Common::SERVER, Common::APP, Common::STAGE)}
  <<: *defaults

test:
  database: #{local_db_name(Common::SERVER, Common::APP, "test")}
  <<: *defaults

#{multisite_config_hash[:apps].keys.collect { |app| yml_section(Common::SERVER, app, Common::STAGE) }}
|

    puts yml if ENV["pdb"] == "t"
    return yml
  end

  private

  def self.yml_section(server, app, stage)
%|#{app}_development:
  database: #{local_db_name(server, app, stage, true)}
  <<: *defaults

#{app}_production:
  database: #{local_db_name(server, app, stage, true)}
  <<: *defaults

#{app}_test:
  database: #{local_db_name(server, app, "test", true)}
  <<: *defaults

|
  end
end
