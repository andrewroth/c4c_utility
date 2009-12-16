require "#{File.dirname(__FILE__)}/../../lib/rake_helper.rb"
require "#{File.dirname(__FILE__)}/../../lib/multisite_helper.rb"

query_databases
@master_stage = multisite_config_hash[:stages].first

for_dbs(:dump) do |p|
  if @databases.nil? || @databases.include?(p[:stage].to_s)
    desc "dumps #{p[:utopian]}"
    task p[:stage] do
      clone :prod => p[:utopian], :file => "tmp/#{p[:utopian]}.sql"
    end
  end

  if p[:legacy] && (@databases.nil? || @databases.include?(p[:legacy].to_s))
    namespace p[:stage] do
      desc "dumps #{p[:legacy]}"
      task :legacy do
        clone :prod => p[:legacy], :file => "tmp/#{p[:legacy]}.sql"
      end
    end
  end
end

for_dbs(:klone) do |p|
  next if p[:stage] == @master_stage

  if @databases.nil? || @databases.include?(p[:master_utopian].to_s)
    desc "clones #{p[:master_utopian]} -> #{p[:utopian]}"
    task :"#{p[:stage]}" do
      clone :prod => p[:master_utopian], :dev => p[:utopian]
    end
  end

  if @databases.nil? || @databases.include?(p[:master_legacy].to_s)
    if p[:legacy]
      namespace p[:stage] do
        desc "clones #{p[:master_legacy]} -> #{p[:legacy]}"
        task :legacy do
          clone :prod => p[:master_legacy], :dev => p[:legacy]
        end
      end
    end
  end
end
