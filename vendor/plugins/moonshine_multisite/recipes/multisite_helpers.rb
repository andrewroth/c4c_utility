def root_config
  return @root_config if @root_config
  file = File.join(File.dirname(__FILE__), '..', 'config', 'database_root.yml')
  if File.exists?(file)
    @root_config = YAML::load(File.open(file))
  else
    throw %|
Aborting. Need a config/database_root.yml file with contents as arguments for
ActiveRecord::Base.establish_connection.

--- 
:host: localhost
:adapter: mysql
:username: username
:password: password

The user given must have access to create and destroy databases.|
  end
end

def load_dump(dump, db)
  throw "Overwriting production database detected! db: #{db}" if %w(summerprojecttool emu ciministry).include?(db.to_s)
  execute_sql "DROP DATABASE IF EXISTS #{db}; CREATE DATABASE #{db}"
  output_command = Kernel.is_windows? ? 'type' : 'cat'
  username = root_config['username']
  password = root_config['password']
  execute_shell "#{output_command} #{dump} | mysql --user #{username} #{db} --password=#{password}"
end

# expects
#
# :prod => <name of production database>
# :dev => <name of development database to copy prod to> OR 
#         <file boolean, which dumps to tmp/#{prod}>
## production will be clone to development
# 
def clone(params)
  prod = params[:prod]
  dev = params[:dev]
  file = params[:file]

  throw "need a :prod database" unless prod.present?
  throw "need a :dev database" unless dev.present? || file.present?

  password = root_config['password']
  options = "--extended-insert --skip-lock-tables --skip-add-locks  --skip-set-charset --skip-disable-keys"

  if file
    dest = "| gzip > #{Rails.root.join("tmp/#{prod}.sql.gz")}"
  else
    dest = "| mysql -h web-db.powertochange.local -u ciministry --password=#{@password} #{dev}"
  end
  execute_shell "mysqldump #{options} -h web-db.powertochange.local -u ciministry --password=#{@password} #{prod} | sed \"2 s/.*/SET SESSION sql_mode='NO_AUTO_VALUE_ON_ZERO';/\" #{dest}"
end

def execute_sql(command)
  unless defined?(ActiveRecord)
    require "active_record"
    load_config
    ActiveRecord::Base.establish_connection root_config
  end

  # grab a connection if there's not one already
  unless @sql
    @sql = ActiveRecord::Base.connection
  end

  for c in command.split(';')
    puts "[SQL] #{c.lstrip.rstrip}"
    STDIN.gets
    @sql.execute c
  end
end

def execute_shell(command)
  puts "[SH ] #{command}"
  STDIN.gets
  system command
end

def for_dbs(action)
  multisite_config_hash[:apps].keys.each do |app|
    namespace app do
      namespace action do
        multisite_config_hash[:servers].keys.each do |server|
          namespace server do
            multisite_config_hash[:stages].each do |stage|
              utopian = utopian_db_name(server, app, stage)
              legacy = legacy_db_name(server, app, stage)
              master_utopian = utopian_db_name(server, app, @master_stage)
              master_legacy = legacy_db_name(server, app, @master_stage)
              yield :server => server, :app => app, :stage => stage,
                :utopian => utopian, :legacy => legacy,
                :master_utopian => master_utopian, :master_legacy => master_legacy
            end
          end
        end
      end
    end
  end
end

# ========

def utopian_db_name(server, app, stage)
  "#{server}.#{app}.#{stage}"
end

def legacy_db_name(server, app, stage)
  hash_path = [ :servers, server, :db_names, app, stage ]
  path_so_far = multisite_config_hash
  for next_segment in hash_path
    if path_so_far[next_segment]
      path_so_far = path_so_far[next_segment]
    else
      return nil
    end
  end
  path_so_far
end

def multisite_config_hash
  return @multisite_config if @multisite_config
  file = "#{File.dirname(__FILE__)}/../moonshine_multisite.yml"
  return {} unless File.exists?(file)
  @multisite_config = YAML.load_file(file)
end

# Sets the key and values in capistrano from the moonshine multisite config
def apply_moonshine_multisite_config(host, stage)
  multisite_config_hash[:servers][host.to_sym].each do |key, value|
    set(key.to_sym, value)
  end
  set :repository, multisite_config_hash[:apps][fetch(:application)]
  set :scm, :svn if !! repository =~ /^svn/
    # Currently there's no way to override the following settings, they're just
    # inherent in moonshine multisite.
    # If someone uses this and wants to override this, we can make a way to 
    # override them in the moonshine_multisite.yml.
    set :deploy_to, "/var/www/#{fetch(:application)}.#{stage}.#{fetch(:domain)}"
    set :branch, "#{host}.#{stage}"
end

# Assumes that your capistrano-ext stages are actually in "host/stage", then
# extracts the host and stage and goes to apply_moonshine_multisite_config
def apply_moonshine_multisite_config_from_cap
  fetch(:stage).to_s =~ /(.*)\/(.*)/
    apply_moonshine_multisite_config $1, $2
end

def get_stages
  multisite_config_hash[:servers].keys.collect { |host|
    multisite_config_hash[:stages].collect{ |stage|
      "#{host}/#{stage}"
    }
  }.flatten
end

def set_stages
  set :stages, get_stages
end
