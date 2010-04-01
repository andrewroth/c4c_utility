require "#{File.dirname(__FILE__)}/../../vendor/plugins/moonshine_multisite/lib/rake_helper.rb"

def clear_sessions(db, table = "sessions")
  puts "clearing sessions in #{db}.#{table}"
  prepare_for_sql db, true
  execute_sql "DELETE FROM #{table};"
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
    
    # clear view cache on pat
    execute_shell "rm /var/www/pat.powertochange.org/current/tmp/cache/views/pat.powertochange.org/main/*"

    # rotate logs
    execute_shell "logrotate -f /etc/logrotate.d/railsapps"
  end
end
