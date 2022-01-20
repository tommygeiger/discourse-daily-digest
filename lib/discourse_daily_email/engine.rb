module DiscourseDailyEmail
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseDailyEmail
    config.after_initialize do
      User.register_custom_field_type('user_daily_email_enabled', :boolean)
      require_dependency 'user_notifications'
      class ::UserNotifications
        
        def apply_notification_styles(email)
                   email.html_part.body = Email::Styles.new(email.html_part.body.to_s).tap do |styles|
                   styles.format_basic
                   styles.format_html
                   end.to_html
                   email
        end
        
        def mailing_list(user, opts={})
          prepend_view_path "plugins/discourse-daily-email/app/views"

          @since = opts[:since] || 1.day.ago
          @since_formatted = short_date(@since)

          topics = Topic
            .joins(:posts)
            .includes(:posts)
            .for_digest(user, 100.years.ago)
            .where("posts.created_at > ?", @since)
            .order("posts.id")

          unless user.staff?
            topics = topics.where("posts.post_type <> ?", Post.types[:whisper])
          end

          @new_topics = topics.where("topics.created_at > ?", @since).uniq
          @existing_topics = topics.where("topics.created_at <= ?", @since).uniq
          @topics = topics.uniq

          return if @topics.empty?

          build_summary_for(user)
          opts = {
            from_alias: I18n.t('user_notifications.mailing_list.from', site_name: SiteSetting.title),
            subject: I18n.t('user_notifications.mailing_list.subject_template', email_prefix: @email_prefix, date: @date),
            mailing_list_mode: true,
            add_unsubscribe_link: true,
            unsubscribe_url: "#{Discourse.base_url}/email/unsubscribe/#{@unsubscribe_key}",
          }

          apply_notification_styles(build_email(@user.email, opts))
        end
      end 

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
              Jobs.enqueue(:user_email, type: :digest, user_id: user_id)
            end
          end

          def target_user_ids
            enabled_ids = UserCustomField.where(name: "user_daily_email_enabled", value: "true").pluck(:user_id)
            User.real
                .activated
                .not_suspended
                .not_silenced
                .joins(:user_option)
                .where(id: enabled_ids)
                .where(staged: false)
                #where subscriber group member
                .pluck(:id)
          end
        end
      end
    end
  end
end
