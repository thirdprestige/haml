class CopyProductionBucketsToDevelopment
  class CopyBucket < Struct.new(:from, :to)
    include Speakable

    def ensure_bucket_exists!
      unless AWS.s3.buckets[to].exists?
        AWS.s3.buckets.create(to)
        speak("Created bucket: #{to}")
      end
    end

    def execute
      ensure_bucket_exists!

      AWS.s3.buckets[from].objects.each do |object|
        if object.acl.grants.any? { |f| f.permission.name.to_s.include?('read') }
          object.copy_to(
            object.key, 
            acl: :public_read,
            bucket_name: to, 
            reduced_redundancy: true
          )
          puts "Copied #{object.key} from #{from} to #{to}"
        end
      end
    rescue AWS::S3::Errors::AccessDenied
      # no worries
    rescue => e
      paste("Problems with buckets // copying #{from} to #{to}", e)
    end
  end

  include Server, Speakable

  def execute
    speak("Copying bucket assets from Production to Development. This may take some time.")

    apps.each do |app|
      next if app.config['AWS_S3_BUCKET'].nil?

      CopyBucket.new(
        app.config['AWS_S3_BUCKET'], 
        "#{app.config['AWS_S3_BUCKET']}-development"
      ).execute
    end

    speak("http://www.beerorkid.com/wp-content/uploads/2007/05/theybestealinmybucketseij5.jpg")
  end
end
