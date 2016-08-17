_ = require 'lodash'
Passport<%= classPrefix %> = require 'passport-<%= instancePrefix %>'

class <%= classPrefix %>Strategy extends Passport<%= classPrefix %>
  constructor: (env) ->
    throw new Error('Missing required environment variable: SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_ID')     if _.isEmpty process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_ID
    throw new Error('Missing required environment variable: SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_SECRET') if _.isEmpty process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_SECRET
    throw new Error('Missing required environment variable: SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CALLBACK_URL')  if _.isEmpty process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CALLBACK_URL

    options = {
      clientID:     process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_ID
      clientSecret: process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CLIENT_SECRET
      callbackUrl:  process.env.SLURRY_<%= constantPrefix %>_<%= constantPrefix %>_CALLBACK_URL
    }

    super options, @onAuthorization

  onAuthorization: (accessToken, refreshToken, profile, callback) =>
    callback null, {
      id: profile.id
      username: profile.username
      secrets:
        credentials:
          secret: accessToken
          refreshToken: refreshToken
    }

module.exports = <%= classPrefix %>Strategy
