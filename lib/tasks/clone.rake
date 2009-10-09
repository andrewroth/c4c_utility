require "#{File.dirname(__FILE__)}/../rake_helper.rb"

namespace "p2c" do
  namespace "clone" do
    desc "clones pat production to development"
    task "pat_dev" => :environment do
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
    task "intranet_dev" => :environment do
      clone :prod => 'ciministry', :dev => 'dev_campusforchrist'
    end
    desc "clones all c4c apps production sites to development"
    task "all" => [ "pat_dev", "emu", "moose", "intranet_dev" ] do
    end
  end
end
