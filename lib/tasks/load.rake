require "#{File.dirname(__FILE__)}/../rake_helper.rb"

namespace "p2c" do
  namespace "load" do
    desc "drops and reloads pat prod db from the latest sql dump in tmp"
    task "pat" do
      load_dump "tmp/summerprojecttool.sql", "pat_prod"
    end
    desc "drops and reloads pat dev db from the latest sql dump in tmp"
    task "pat_dev" do
      load_dump "tmp/spt_dev.sql", "pat_dev"
    end
    desc "drops and reloads pulse db from the latest sql dump in tmp"
    task "pulse" do
      load_dump "tmp/emu.sql", "pulse_prod"
    end
    desc "drops and reloads emu db from the latest sql dump in tmp"
    task "emu" do
      load_dump "tmp/emu_stage.sql", "pulse_stage_emu"
    end
    desc "drops and reloads moose db from the latest sql dump in tmp"
    task "moose" do
      load_dump "tmp/emu_dev.sql", "pulse_dev_moose"
    end
    desc "drops and reloads intranet prod db from the latest sql dump in tmp"
    task "intranet" do
      load_dump "tmp/ciministry.sql", "cim_prod"
    end
    desc "drops and reloads intranet dev db from the latest sql dump in tmp"
    task "intranet_dev" do
      load_dump "tmp/dev_campusforchrist.sql", "cim_dev"
    end
    desc "drops and reloads all c4c dbs from the latest sql dumps in tmp"
    task "all" => [ "pat", "pat_dev", "pulse", "emu", "moose", "intranet", "intranet_dev" ] do
    end
  end
end
