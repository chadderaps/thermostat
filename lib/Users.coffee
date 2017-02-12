debug = require('debug') 'thermostat:users'
DynamoDB = require './dynamo-db'

module.exports =
class Users

  constructor: (maybe) ->

    return if maybe

    dynamoOptions = {
      endpoint: 'http://server:8000'
      tables: [
        {
          id: 'users'
          name: 'THERMOSTAT-USERS'
          timeout: 0
        }
        {
          id: 'user-link'
          name: 'THERMOSTAT-USERS.LINK'
          timeout: 0
          keyGen: @keyGen.bind @
        }
      ]
    }

    @db = new DynamoDB dynamoOptions
    @isInit = {
      users: false
      'user-link': false
    }

    @isInitialized = false

    @db.exists 'users', (err, exists) =>
      throw err if err
      debug "users exists=#{exists}"
      if not exists
        @db.create 'users', (err, exists) =>
          throw err if err
          @init 'users'
      else
        @init 'users'
    @db.exists 'user-link', (err, exists) =>
      throw err if err
      debug "user-link exists=#{exists}"
      if not exists
        @db.create 'user-link', (err, exists) =>
          throw err if err
          @init 'user-link'
      else
        @init 'user-link'

    @userHash = {}

  hash: (key) ->
    hashKey = 5381
    for c in key.split ''
      hashKey = (hashKey << 5) + hashKey + c.charCodeAt 0
    return hashKey.toString

  keyGen: (baseKey, callback) ->
    callback baseKey

  init: (type) ->
    @isInit[type] = true

    debug "Init #{type}"
    debug "#{@isInit['users']} #{@isInit['user-link']}"

    if @isInit['users'] and @isInit['user-link']
      @isInitialized = true
      debug "Is initialized"

  get: (userId, callback) ->

    if not @isInitialized
      setTimeout (() =>
        @get userId, callback
      ).bind @, 1000
      return

    debug 'Getting user by ' + userId

    @db.get 'user-link', userId, (err, userLink) =>
      throw err if err

      if userLink?._id?

        @db.get 'users', userLink.userUUID, (err, profile) =>

          userUUID = profile?._id
          profile.id = userUUID

          if userUUID
            @userHash[userUUID] = profile

          callback profile
      else
        callback null

  getUserById: (id, callback) ->
    return callback @userHash[id]

  getUserByToken: (token, callback) ->
    return callback null, @userHash[token]

  add: (userId, profile, callback) ->

    if not @isInitialized
      setTimeout (() =>
        @add userId, profile, callback
      ).bind @, 1000
      return

    debug 'Adding user ' + userId

    @userHash[userId] = profile

    newProfile = Object.assign {}, profile

    delete newProfile.id
    delete newProfile._raw
    delete newProfile._json

    @db.put 'users', newProfile, (err, item) =>
      debug item
      throw err if err
      userLink = {
        id: userId
        userUUID: item._id
        provider: item.provider
      }
      @db.put 'user-link', userLink, (err, link) =>
        throw err if err
        @userHash[link.userUUID] = newProfile
        newProfile.id = link.userUUID
        callback @userHash[link.userUUID]
