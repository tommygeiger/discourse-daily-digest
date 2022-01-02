import { observes } from 'ember-addons/ember-computed-decorators';
import { default as computed } from "ember-addons/ember-computed-decorators";
import EmailPreferencesController from 'discourse/controllers/preferences/emails';
import UserController from 'discourse/controllers/user';

export default {
  name: 'daily_email',

  initialize(container){
    EmailPreferencesController.reopen({
      userDailyEmailEnabled(){
        const user = this.get("model");
        return user.get("custom_fields.user_daily_email_enabled");
      },

      @observes("model.custom_fields.user_daily_email_enabled")
      _setUserDailyEmail(){
        var attrNames = this.get("saveAttrNames");
        attrNames.push('custom_fields');
        this.set("saveAttrNames", attrNames);
        const user = this.get("model");
        const userDailyEmailEnabled = user.custom_fields.user_daily_email_enabled;
        user.set("custom_fields.user_daily_email_enabled", userDailyEmailEnabled);
      }
    })
  }
}
