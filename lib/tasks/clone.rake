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

  puts "SQL: #{command}"
  @sql.execute command
end

def execute_shell(command)
  puts "SHELL: #{command}"
  system command
end

def clear_sessions(domain)
  execute_shell "cd /var/www/#{domain}/current && RAILS_ENV=production rake tmp:cache:clear"
end

namespace "p2c" do
  desc "cleans up all c4c app data; removes all session data"
  task "cleanup" => :environment do
    # clean up sessions stuff
    clear_sessions "pat.powertochange.org"
    clear_sessions "dev.pat.powertochange.org"
    clear_sessions "pulse.campusforchrist.org"
    clear_sessions "moose.campusforchrist.org"
    clear_sessions "emu.campusforchrist.org"
    
    # intranet
    execute_sql "USE ciministry; delete from site_session;"
    execute_sql "USE dev_campusforchrist; delete from site_session;"

    # rotate logs
    execute_shell "logrotate -vf /etc/logrotate.d/railsapps"
  end

  namespace "clone" do
    desc "clones pat production to development"
    task "dev.pat" => :environment do
      clone :prod => 'summerprojecttool', :dev => 'spt_dev'
    end
    desc "clones pulse database to emu"
    task "emu" => :environment do
      clone :prod => 'emu', :dev => 'emu_dev'
    end
    desc "clones pulse database to moose"
    task "moose" => :environment do
      clone :prod => 'emu', :dev => 'emu_stage'
    end
    desc "clones intranet database to dev intranet"
    task "dev.intranet" => :environment do
      clone :prod => 'ciministry', :dev => 'dev_campusforchrist'
    end
    desc "clones all c4c apps production sites to development"
    task "all" => [ "dev.pat", "emu", "moose", "dev.intranet" ] do
    end
  end
end
