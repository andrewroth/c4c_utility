def utopian_db_name(server, app, stage)
  "#{server || 'server'}.#{app || 'app'}.#{stage || 'stage'}"
end

def legacy_db_name(server, app, stage)
  return 'legacy_db_name' unless server && app && stage
  hash_path = [ :servers, server, :db_names, app, stage ]
  path_so_far = multisite_config_hash
  for next_segment in hash_path
    if path_so_far[next_segment]
      path_so_far = path_so_far[next_segment]
    else
      return nil
    end
  end
  path_so_far
end

def multisite_config_hash
  return @multisite_config if @multisite_config
  file = "#{File.dirname(__FILE__)}/../moonshine_multisite.yml"
  return {} unless File.exists?(file)
  @multisite_config = YAML.load(ERB.new(File.read(file)).result)
end

# Sets the key and values in capistrano from the moonshine multisite config
def apply_moonshine_multisite_config(server, stage)
  multisite_config_hash[:servers][server.to_sym].each do |key, value|
    set(key.to_sym, value)
  end
  set :server_only, server
  set :stage_only, stage
  set :repository, multisite_config_hash[:apps][fetch(:application)]
  set :scm, :svn if !! repository =~ /^svn/
  # Currently there's no way to override the following settings, they're just
  # inherent in moonshine multisite.
  # If someone uses this and wants to override this, we can make a way to 
  # override them in the moonshine_multisite.yml.
  set :deploy_to, "/var/www/#{fetch(:application)}.#{stage}.#{fetch(:domain)}"
  set :branch, "#{server}.#{stage}"
end

# Assumes that your capistrano-ext stages are actually in "host/stage", then
# extracts the host and stage and goes to apply_moonshine_multisite_config
def apply_moonshine_multisite_config_from_cap
  fetch(:stage).to_s =~ /(.*)\/(.*)/
  apply_moonshine_multisite_config $1, $2
end

def get_stages
  multisite_config_hash[:servers].keys.collect { |host|
    multisite_config_hash[:stages].collect{ |stage|
      "#{host}/#{stage}"
    }
  }.flatten + (multisite_config_hash[:legacy_stages].collect(&:to_s) || [])
end

def set_stages
  set :stages, get_stages
end
