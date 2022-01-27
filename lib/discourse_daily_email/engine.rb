module DiscourseDailyEmail
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyEmail
    config.after_initialize do
      User.register_custom_field_type('user_daily_email_enabled', :boolean)

      require_dependency 'email'
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

      module Jobs
        class DailyEmail < ::Jobs::Scheduled
          every 1.minute

          def execute(args)
            target_users.each do |user|

              message, skip_reason = UserNotifications.public_send(:digest, user, since: user.last_seen_at)
              
              if message
                message.to = user.email
                begin
                  Email::Sender.new(message, :digest).send
                  render json: success_json
                rescue => e
                  render json: { errors: [e.message] }, status: 422
                end
              else
                render json: { errors: skip_reason }
              end
            end

          end

          def target_users
            enabled_ids = UserCustomField.where(name: "user_daily_email_enabled", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .joins(:user_option)
                .where(id: enabled_ids)
                #where subscriber group member
          end
        end
      end
    end
  end
end
