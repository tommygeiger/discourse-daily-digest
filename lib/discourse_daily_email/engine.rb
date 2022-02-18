module DiscourseDailyEmail
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyEmail
    config.after_initialize do
      
      User.register_custom_field_type('opt_out', :boolean)
      require_dependency 'user_serializer'
      class ::UserSerializer
        attributes :opt_out
        def opt_out
          if !object.custom_fields["opt_out"]
            object.custom_fields["opt_out"] = false #opt in by default
            object.save
          end
          object.custom_fields["opt_out"]
        end
      end

      module Jobs
        class DailyEmail < ::Jobs::Scheduled
          daily at: 10.hours #10 UTC = 5am EST

          def execute(args)            
            users.each do |user|
              message = UserNotifications.digest(user, since: 1.day.ago)
              Email::Sender.new(message, :digest).send
            end                
          end

          def users
            opt_out_ids = UserCustomField.where(name: "opt_out", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .joins(:user_option)
                .where.not(id: opt_out_ids)
          end
        end
      end
    end
  end
end
