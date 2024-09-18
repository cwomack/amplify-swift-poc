import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true
  },
    
  userAttributes: {
    // specify a "birthdate" attribute
    birthdate: {
      mutable: true,
      required: false,
    },
    "custom:display_name": {
      dataType: "String",
      mutable: true,
      maxLen: 16,
      minLen: 1,
    },
    "custom:favorite_number": {
      dataType: "Number",
      mutable: true,
      min: 1,
      max: 100,
    },
    "custom:is_beta_user": {
      dataType: "Boolean",
      mutable: true,
    },
    "custom:started_free_trial": {
      dataType: "DateTime",
      mutable: true,
    },
  },

  multifactor: {
    mode: 'REQUIRED',
    totp: true
  }
});
