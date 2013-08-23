module Server
  class App < Struct.new(:name)
    include Server, Speakable

    class << self
      def default
        @default ||= self.new(ENV['HEROKU_APP_NAME'])
      end
    end

    def bust!
      server.put_config_vars(name, 'RAILS_CACHE_ID' => Time.now.to_i)
      speak("Busted cache for #{name}")
    rescue => e
      paste("Could not bust cache for #{name}", e)
    end

    def collaborate email
      server.post_collaborator(name, email)
    end

    def collaborators
      @collaborators ||= server.get_collaborators(name).body.map do |response|
        response['email']
      end
    end

    def configure key, value
      server.post_configuration(key => value)
    end

    def addons
      @addons ||= server.get_addons(name).body.map do |addon|
        addon['name']
      end
    end

    def backups
      unless config.keys.include?('PGBACKUPS_URL')
        server.post_addon(name, 'pgbackups:auto-month')
      end

      @backups ||= Heroku::Client::Pgbackups.new(config['PGBACKUPS_URL'])
    end

    def config
      @config ||= server.get_config_vars(name).body
    end

    def demo?
      # To add an app to this list, 
      # we need to name the app starting with the prefix 'demo-'
      # 
      # For example:
      # * demo-third-prestige
      # * demo-blp
      # * demo-simple-donation
      #
      name.start_with?('demo-') 
    end

    def to_s
      name.to_s
    end
  end

  class List
    include Server, Speakable

    def initialize(*args); end

    def execute
      paste(
        "List of Apps Haml has access to:", 
        apps.sort_by(&:name).map(&:name).join("\n")
      )
    end
  end

  def server
    @server ||= Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
  end

  def apps
    @apps ||= server.get_apps.body.map do |response|
      App.new(response['name'])
    end
  end
end
