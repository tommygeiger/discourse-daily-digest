import { observes } from 'ember-addons/ember-computed-decorators';
import { default as computed } from "ember-addons/ember-computed-decorators";
import EmailPreferencesController from 'discourse/controllers/preferences/emails';
import UserController from 'discourse/controllers/user';

export default {
  name: 'daily_digest',

  initialize(container){
    EmailPreferencesController.reopen({
      dailyDigestUnsubscribe(){
        const user = this.get("model");
        return user.get("custom_fields.unsubscribe");
      },

      @observes("model.custom_fields.unsubscribe")
      _setUserDailyDigest(){
        var attrNames = this.get("saveAttrNames");
        attrNames.push('custom_fields');
        this.set("saveAttrNames", attrNames);
        const user = this.get("model");
        const unsubscribe = user.custom_fields.unsubscribe;
        user.set("custom_fields.unsubscribe", unsubscribe);
      }
    })
  }
}
