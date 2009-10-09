# expects
#
# :prod => <name of production database>
# :dev => <name of development database>
#
# production will be clone to development
# 
def clone(params)
  prod = params[:prod]
  dev = params[:dev]

  throw "need a :prod database" unless prod.present?
  throw "need a :dev database" unless dev.present?

  # grab password if haven't already
  unless @password.present?
    STDOUT.print "database password: "
    @password = STDIN.gets.chomp
  end

  execute_shell "mysqldump -h web-db.powertochange.local -u ciministry --password=#{@password} --skip-lock-tables #{prod} | sed \"2 s/.*/SET SESSION sql_mode='NO_AUTO_VALUE_ON_ZERO';/\" | mysql -h web-db.powertochange.local -u ciministry --password=#{@password} #{dev}"
end

def execute_sql(command)
  # grab a connection if there's not one already
  unless @sql
    @sql = ActiveRecord::Base.connection
  end

  for c in command.split(';')
    puts "SQL: #{c}"
    @sql.execute c
  end
end

def execute_shell(command)
  puts "SHELL: #{command}"
  system command
end
