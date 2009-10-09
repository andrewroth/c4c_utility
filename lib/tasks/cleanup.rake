require "#{File.dirname(__FILE__)}/../rake_helper.rb"

def clear_sessions(db, table = "sessions")
  puts "clearing sessions in #{db}.#{table}"
  execute_sql "USE #{db}; DELETE FROM #{table};"
  #execute_shell "cd /var/www/#{domain}/current && RAILS_ENV=production rake db:sessions:clear"
end

namespace "p2c" do
  desc "cleans up all c4c app data; removes all session data"
  task "cleanup" => :environment do
    # pat
    clear_sessions "summerprojecttool"
    clear_sessions "spt_dev"
    # emu
    clear_sessions "emu"
    clear_sessions "emu_dev"
    clear_sessions "emu_stage"
    # intranet
    clear_sessions "ciministry", "site_session"
    clear_sessions "dev_campusforchrist", "site_session"
    
    # rotate logs
    execute_shell "logrotate -f /etc/logrotate.d/railsapps"
  end
end
