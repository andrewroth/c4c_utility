class MoonshineMultisiteGenerator < Rails::Generator::NamedBase
  @@config = YAML::load(File.read(Rails.root.join(File.dirname(__FILE__), '../../../moonshine_multisite/moonshine_multisite.yml')))
  STAGES = @@config.delete(:stages)
  LEGACY_STAGES = @@config.delete(:legacy_stages) || []
  
  def initialize(runtime_args, runtime_options = {})
    @help = runtime_args.include?('--help') || runtime_args.include?('-h') || runtime_args.empty?
    if @help
      runtime_args = [ '--help' ]
      @host = 'host_identifier'
    else
      @host = runtime_args.delete_at(1).to_sym
    end

    super
  end

  def attributes
    #return @@config[@@config.keys.first] if @help
    return {} if @help
    @attributes ||= @@config[:servers][@host].merge(Hash[*@args.collect { |attribute|
      attribute.split('=')
    }.flatten])
  end

  def repository() 
    @apps ||= @@config[:apps]
    @apps[@name]
  end

  def domain() attributes["domain"] end

  def manifest
    record do |m|
      # manifests
      m.directory "app/manifests"
      m.file "manifests/application_manifest.rb", "app/manifests/application_manifest.rb"
      m.directory "app/manifests/templates"
      m.file "manifests/templates/passenger.vhost.erb", "app/manifests/templates/passenger.vhost.erb"
      m.file "manifests/templates/README", "app/manifests/templates/README"
      m.file "config/deploy/moonshine.yml", "config/moonshine.yml"

      # config
      m.directory "config/deploy"
      # generate host configs
      m.directory "config/deploy/#{@host}"
      m.directory "config/deploy/local/#{@host}"
      m.template "config/deploy/moonshine_host.yml", "config/deploy/#{@host}/moonshine.yml"
      for local in [ false ] # eventuall I want to add manifests for setting up for local dev
        for @stage in STAGES
          m.template "config/deploy/deploy.host.rb.erb", 
            "config/deploy/#{'local/' if local}#{@host}/#{@stage}.rb",
            :assigns => { :server => "#{@@config[:server]}" }
          m.template "config/deploy/moonshine_stage.yml", 
            "config/deploy/#{'local/' if local}#{@host}/#{@stage}_moonshine.yml", 
            :assigns => { :domain => domain, :host => @host, :stage => @stage, :local => local }
        end
      end
      # generate deploy.rb with appropriate stages
      stages = LEGACY_STAGES # keep some default tasks available
      stages += @@config[:servers].keys.collect{ |host|
        STAGES.collect { |stage| 
          [ "#{host}/#{stage}", "#{host}/local/#{stage}" ]
        }
      }.flatten
      m.template "config/deploy.rb.erb", "config/deploy.rb", :assigns => { :stages => stages }
    end
  end
end
