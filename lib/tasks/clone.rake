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

  execute_sql "drop database #{dev}"
  execute_sql "create database #{dev}"

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

  puts "SQL: #{command}"
  #@sql.execute command
end

def execute_shell(command)
  puts "SHELL: #{command}"
end

namespace "p2c" do
  task "cleanup" do
    # clean up sessions stuff
    execute_shell "cd /var/www/pat.powertochange.org/current && RAILS_ENV=production rake tmp:cache:clear"
    execute_shell "cd /var/www/pulse.powertochange.org/current && RAILS_ENV=production rake tmp:cache:clear"
    # execute_sql "USE ciministry; delete from site_session;"
  end

  namespace "clone" do
    task "dev.pat" => :environment do
      clone :prod => 'summerprojecttool', :dev => 'spt_dev'
    end
    task "emu" => :environment do
      clone :prod => 'emu', :dev => 'emu_dev'
    end
    task "moose" => :environment do
      clone :prod => 'emu', :dev => 'emu_stage'
    end
    task "dev.intranet" => :environment do
      clone :prod => 'ciministry', :dev => 'dev_campusforchrist'
    end
    task "all" => [ "dev.pat", "emu", "moose", "dev.intranet" ] do
    end
  end
end
