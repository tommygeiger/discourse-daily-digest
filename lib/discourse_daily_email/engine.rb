module DiscourseDailyDigest
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyDigest
    config.after_initialize do
      
      User.register_custom_field_type('unsubscribe', :boolean)
      require_dependency 'user_serializer'
      class ::UserSerializer
        attributes :unsubscribe
        def unsubscribe
          if !object.custom_fields["unsubscribe"]
            object.custom_fields["unsubscribe"] = false #on by default
            object.save
          end
          object.custom_fields["unsubscribe"]
        end
      end

      module Jobs
        class DailyDigest < ::Jobs::Scheduled
          daily at: 10.hours #10 UTC = 5am EST

          def execute(args)            
            users.each do |user|
              message = UserNotifications.digest(user, since: 1.day.ago)
              Email::Sender.new(message, :digest).send
            end                
          end

          def users
            unsubscribed_ids = UserCustomField.where(name: "unsubscribe", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .joins(:user_option)
                .where.not(id: unsubscribed_ids)
          end
        end
      end
    end
  end
end
