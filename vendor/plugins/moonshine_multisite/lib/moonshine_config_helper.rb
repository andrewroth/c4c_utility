# Utilities available throughout moonshine.
#
class MoonshineConfigHelper
  # Load a yaml file if it exists.  The yaml file is expected to produce a hash.
  def self.load_yaml_hash(yaml_path)
    File.exists?(yaml_path) ? YAML::load(ERB.new(IO.read(yaml_path)).result) : {}
  end

  # Look in all the spots config files can be in, and merge them in to one
  # and return the resulting hash.  Expects these config files to always return
  # hashes.
  #
  # Ex. name = moonshine.yml, rails_env = development, stage = staging/sub
  #
  #   1) config/moonshine.yml
  #   2) config/development/moonshine.yml
  #   3) config/deploy/staging/moonshine.yml     [ stage is split on / ]
  #   4) config/deploy/staging/sub/moonshine.yml [ second part of stage split ]
  #   4) config/deploy/staging/sub_moonshine.yml [ append stage and _moonshine.yml ]
  #
  def self.load_configs(name, rails_root, rails_env, stage = nil)
    stage = stage.to_s
    config = {}
    config.merge!(load_yaml_hash(File.join(rails_root, "config", name)))
    config.merge!(load_yaml_hash(File.join(rails_root, "config", rails_env, name)))
    if stage != ""
      stage.split("/").inject("") { |lastcheck, s|
        check = lastcheck + "/" + s
        config.merge!(load_yaml_hash(File.join(rails_root, "config", "deploy", check, name)))
        check
      }
      config.merge!(load_yaml_hash(File.join(rails_root, "config", "deploy", "#{stage}_#{name}")))
    end
    config
  end
end

def apply_moonshine_config
  config = MoonshineConfigHelper.load_configs('moonshine.yml', ENV['RAILS_ROOT'] || Dir.pwd, 
                                              fetch(:rails_env, 'production'), fetch(:stage, nil))
  config.each do |key, value|
    set(key.to_sym, value)
  end
end


