namespace :moonshine do
  namespace :secure do
    desc "uploads the certificate files in app/manifests/assets/private/certs to /tmp/moonshine_config_files"
    task :upload_certs do
      destroy_config_files
      upload "app/manifests/private/certs/", 
    "/tmp/moonshine_config_files/", 
    :recursive => true
    end

    desc "downloads a remote private repoistory to app/manifests/assets/private"
    task :download_private, :roles => :private do
      set :user, fetch(:private_user)
      server fetch(:private_host), :private
      download fetch(:private_path), "app/manifests/assets/private",
        :recursive => true
    end

    desc "destroys the local app/manifests/assets/private directory"
    task :destroy_private do
      FileUtils.rm_rf "app/manifests/assets/private"
    end

    desc "destroys the remote /tmp/moonshine_config_files directory"
    task 'destroy_config_files' do
      run "rm -rf /tmp/moonshine_config_files"
    end
  end
end
