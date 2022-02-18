import { observes } from 'ember-addons/ember-computed-decorators';
import { default as computed } from "ember-addons/ember-computed-decorators";
import EmailPreferencesController from 'discourse/controllers/preferences/emails';
import UserController from 'discourse/controllers/user';

export default {
  name: 'daily_email',

  initialize(container){
    EmailPreferencesController.reopen({
      dailyEmailUnsubscribe(){
        const user = this.get("model");
        return user.get("custom_fields.daily_email_unsubscribe");
      },

      @observes("model.custom_fields.daily_email_unsubscribe")
      _setUserDailyEmail(){
        var attrNames = this.get("saveAttrNames");
        attrNames.push('custom_fields');
        this.set("saveAttrNames", attrNames);
        const user = this.get("model");
        const dailyEmailUnsubscribe = user.custom_fields.daily_email_unsubscribe;
        user.set("custom_fields.daily_email_unsubscribe", dailyEmailUnsubscribe);
      }
    })
  }
}
