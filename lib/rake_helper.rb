require File.join(File.dirname(__FILE__), 'detect_windows')

def load_config
  file = File.join(File.dirname(__FILE__), '..', 'config', 'database.yml')
  if File.exists?(file)
    @config ||= YAML::load(File.open(file))
  end
end

def load_dump(dump, db)
  throw "Overwriting production database detected! db: #{db}" if %w(summerprojecttool emu ciministry).include?(db.to_s)
  execute_sql "DROP DATABASE IF EXISTS #{db}; CREATE DATABASE #{db}"
  output_command = Kernel.is_windows? ? 'type' : 'cat'
  username = @config['development']['username'] || 'root'
  password = @config['development']['password'] || ''
  execute_shell "#{output_command} #{dump} | mysql --user #{username} #{db} --password=#{password}"
end

# expects
#
# :prod => <name of production database>
# :dev => <name of development database to copy prod to> OR 
#         <file boolean, which dumps to tmp/#{prod}>
#
# production will be clone to development
# 
def clone(params)
  prod = params[:prod]
  dev = params[:dev]
  file = params[:file]

  throw "need a :prod database" unless prod.present?
  throw "need a :dev database" unless dev.present? || file.present?

  # grab password if haven't already
  if !@password.present? && File.exists?(pwdfile = Rails.root.join("config/dbpw"))
    @password = File.read(pwdfile).chomp
  elsif !@password.present?
    STDOUT.print "database password: "
    @password = STDIN.gets.chomp
  end

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
    ActiveRecord::Base.establish_connection @config['development']
  end

  # grab a connection if there's not one already
  unless @sql
    @sql = ActiveRecord::Base.connection
  end

  for c in command.split(';')
    puts "[SQL] #{c.lstrip.rstrip}"
    @sql.execute c
  end
end

def execute_shell(command)
  puts "[SH ] #{command}"
  system command
end
