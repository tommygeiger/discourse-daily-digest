# name: discourse-daily-digest
# about: Scheduled daily email digest
# version: 1.0
# author: Tommy Geiger
# url: https://www.github.com/tommygeiger/discourse-daily-digest

enabled_site_setting :daily_digest_enabled
DiscoursePluginRegistry.serialized_current_user_fields << "unsubscribe"
load File.expand_path('../lib/discourse_daily_email/engine.rb', __FILE__)
after_initialize do
  register_editable_user_custom_field :unsubscribe
end
