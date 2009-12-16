before "multistage:prepare", "multistage:prepare_nested_locations"

namespace :multistage do
  desc "helper task to make prepare work with stages with subfolders like \"folder/stage\""
  task :prepare_nested_locations do
    location = fetch(:stage_dir, "config/deploy")
    stages.each do |name|
      FileUtils.mkdir_p(File.join(location, File.dirname(name)))
    end
  end
end
