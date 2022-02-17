module DiscourseDailyEmail
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyEmail
    config.after_initialize do
      
      User.register_custom_field_type('user_daily_email_enabled', :boolean)
      require_dependency 'user_serializer'
      class ::UserSerializer
        attributes :user_daily_email_enabled
        def user_daily_email_enabled
          if !object.custom_fields["user_daily_email_enabled"]
            object.custom_fields["user_daily_email_enabled"] = true
            object.save
          end
          object.custom_fields["user_daily_email_enabled"]
        end
      end

      module Jobs
        class DailyEmail < ::Jobs::Scheduled
          daily at: 10.hours #10am UTC = 5am EST

          def execute(args)            
            users.each do |user|
              message = UserNotifications.digest(user, since: 1.day.ago)
              Email::Sender.new(message, :digest).send
            end                
          end

          def users
            enabled_ids = UserCustomField.where(name: "user_daily_email_enabled", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .joins(:user_option)
                .where(id: enabled_ids)
          end
        end
      end
    end
  end
end
