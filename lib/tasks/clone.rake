require "#{File.dirname(__FILE__)}/../rake_helper.rb"

namespace "p2c" do
  namespace "clone" do
    desc "clones pat production to development"
    task "pat_dev" do
      clone :prod => 'summerprojecttool', :dev => 'spt_dev'
    end
    desc "clones pulse db to emu"
    task "emu" do
      clone :prod => 'emu', :dev => 'emu_stage'
    end
    desc "clones pulse db to moose"
    task "moose" do
      clone :prod => 'emu', :dev => 'emu_dev'
    end
    desc "clones intranet db to dev intranet"
    task "intranet_dev" do
      clone :prod => 'ciministry', :dev => 'dev_campusforchrist'
    end
    desc "clones all c4c apps production sites to development"
    task "all" => [ "pat_dev", "emu", "moose", "intranet_dev" ] do
    end
  end
  namespace "dump" do
    desc "dumps pat prod db"
    task "pat" do
      clone :prod => 'summerprojecttool', :file => true
    end
    desc "dumps pat dev db"
    task "pat_dev" do
      clone :prod => 'spt_dev', :file => true
    end
    desc "dumps pulse db"
    task "pulse" do
      clone :prod => 'emu', :file => true
    end
    desc "dumps emu db"
    task "emu" do
      clone :prod => 'emu_stage', :file => true
    end
    desc "dumps moose db"
    task "moose" do
      clone :prod => 'emu_dev', :file => true
    end
    desc "dumps intranet prod db"
    task "intranet" do
      clone :prod => 'ciministry', :file => true
    end
    desc "dumps intranet dev db"
    task "intranet_dev" do
      clone :prod => 'dev_campusforchrist', :file => true
    end
    desc "dumps all c4c intranet dbs to file"
    task "all" => [ "pat", "pat_dev", "pulse", "emu", "moose", "intranet", "intranet_dev" ] do
    end
  end
end
