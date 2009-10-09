require "#{File.dirname(__FILE__)}/../rake_helper.rb"

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
    execute_shell "logrotate -f /etc/logrotate.d/railsapps"
  end
end
