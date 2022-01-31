# name: discourse-daily-email
# about: Daily email digest for subscribers
# version: 1.0
# author: Tommy Geiger
# url: https://www.github.com/tommygeiger/discourse-daily-email

enabled_site_setting :daily_email_enabled
DiscoursePluginRegistry.serialized_current_user_fields << "user_daily_email_enabled"
load File.expand_path('../lib/discourse_daily_email/engine.rb', __FILE__)
after_initialize do
  register_editable_user_custom_field :user_daily_email_enabled
end
