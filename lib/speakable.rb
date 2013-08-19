module Speakable
  def campfire
    unless %w(CAMPFIRE_SUBDOMAIN CAMPFIRE_TOKEN CAMPFIRE_ROOM_ID).all? { |f| ENV.keys.include?(f) }
      raise "Check Campfire config: $CAMPFIRE_SUBDOMAIN, $CAMPFIRE_ROOM_ID, $CAMPFIRE_TOKEN" 
    end

    @campfire ||= Tinder::Campfire.new(
      ENV['CAMPFIRE_SUBDOMAIN'], 
      token: ENV['CAMPFIRE_TOKEN']
    )
  end

  def room
    @room ||= campfire.find_room_by_id(ENV['CAMPFIRE_ROOM_ID'])
  end

  def paste(message, error)
    speak(message)
    room.paste(
      error.respond_to?(:message) ? 
        [error.class.name, error.message, *error.backtrace].join("\n") :
        error
    )
  end

  def speak *messages
    messages.flatten.each do |line|
      room.speak(line)
    end
  end
end
