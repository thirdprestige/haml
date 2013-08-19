class Stream
  class GitHubAuthorizor < Struct.new(:username)
    include Speakable 

    def execute
      if username.empty?
        speak("Please provide a GitHub username: `haml authorize @HamlTheHamster`")
      else
        speak("~haml authorize #{username}: n/a")
      end
    end
  end

  class Help
    include Speakable

    def execute
      speak("~haml apps :: List each app name Haml has access to")
      speak("~haml authorize @hamlthehamster :: Add GitHub user '@hamlthehamster' to our GitHub Team")
      speak("~haml bucket :: Copy all our production S3 buckets to development")
      speak("~haml bust third-prestige :: Bust the cache for the 'third-prestige' app") 
      speak("~haml collaborate haml@thirdprestige.com :: Add 'haml@thirdprestige.com' to all of our Heroku Apps")
      speak("~haml dance")
      speak("~haml help :: Display this help message")
    end
  end

  class Message < Struct.new(:body)
    class << self
      def from(json)
        message = JSON.parse(json)
        
        if message['user_id'].nil?
          Struct.new(:execute).new
        else          
          self.new(message['body'])
        end
      end
    end

    include Speakable

    def execute
      to, command, arguments = body.split(' ').map(&:strip)

      return unless to == 'haml'

      case command
      when 'apps'        then Server::List.new(arguments)
      when 'authorize'   then GitHubAuthorizor.new(arguments)
      when 'bucket'      then CopyProductionBucketsToDevelopment.new
      when 'bust'        then BustCache.new(arguments)
      when 'collaborate' then HerokuCollaborator.new(arguments)
      when 'dance'       then Dance.new
      when 'rebuild'     then DemoRebuilder.new
      else                    Help.new
      end.execute

    rescue => e
      paste("Could not run command.", e)
      Help.new.execute
    end
  end

  include Speakable

  def execute
    room.join

    EventMachine::run do
      stream = Twitter::JSONStream.connect({
        auth: "#{ENV['CAMPFIRE_TOKEN']}:x",
        host: 'streaming.campfirenow.com',
        path: "/room/#{ENV['CAMPFIRE_ROOM_ID']}/live.json"
      })

      stream.each_item do |item|
        Message.from(item).execute
      end

      stream.on_error do |message|
        puts "ERROR:#{message.inspect}"
      end

      stream.on_max_reconnects do |timeout, retries|
        puts "Tried #{retries} times to connect."
        exit
      end
    end
  end
end
