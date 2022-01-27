module DiscourseDailyEmail
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyEmail
    config.after_initialize do
      User.register_custom_field_type('user_daily_email_enabled', :boolean)
      require_dependency 'user_notifications'
      require_dependency 'user_serializer'
      
      class ::UserSerializer
        attributes :user_daily_email_enabled
        def user_daily_email_enabled
          if !object.custom_fields["user_daily_email_enabled"]
            object.custom_fields["user_daily_email_enabled"] = false
            object.save
          end
          object.custom_fields["user_daily_email_enabled"]
        end
      end

      module ::Jobs
        class EnqueueDailyEmail < Jobs::Scheduled
          every 1.minute
          def execute(args)
            target_user_ids.each do |user_id|
              Jobs.enqueue(:user_email, type: UserNotifications::digest, user_id: user_id)
            end
          end

          def target_user_ids
            enabled_ids = UserCustomField.where(name: "user_daily_email_enabled", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .joins(:user_option)
                .where(id: enabled_ids)
                #where subscriber group member
                .pluck(:id)
          end
        end
      end
    end
  end
end
