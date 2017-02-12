debug = require('debug') 'thermostat:devices'
DynamoDB = require './dynamo-db'

module.exports =
class Devices

  constructor: (maybe) ->

    return if maybe

    dynamoOptions = {
      endpoint: 'http://server:8000'
      tables: [
        {
          id: 'devices'
          name: 'THERMOSTAT-DEVICES'
          timeout: 0
          keyGen: (key, cb) =>
             return cb key
        }
      ]
    }

    @db = new DynamoDB dynamoOptions
    @isInit = {
      devices: false
    }

    @isInitialized = false

    for table in dynamoOptions.tables
      debug "Checking #{table.id}"
      @db.exists table.id, (err, exists) =>
        throw err if err
        debug " exists=#{exists}"
        if not exists
          @db.create table.id, (err, exists) =>
            throw err if err
            @init table.id
        else
          @init table.id

    @userHash = {}

  init: (type) ->
    @isInit[type] = true

    debug "Init #{type}"

    initialized = true

    for k,v of @isInit
      if not v
        debug "#{k} = #{v}"
        initialized = false

    @isInitialized = initialized
    debug "Is initialized #{@isInitialized}"
    return

  wait: (callback) ->
    if not @isInitialized
      setTimeout callback, 1000
    return not @isInitialized

  list: (callback) ->

    return if @wait () =>
      @list callback

    @db.getItems 'devices', (err, items) =>
      return callback err, null if err
      debug "got #{items}"
      for item in items
        debug item
      callback null, items

  get: (deviceId, callback) ->

    return if @wait () =>
      @get deviceId, callback

    debug 'Getting device by ' + deviceId
    @db.get 'devices', deviceId , (err, profile) =>
      return callback err if err
      callback null, profile

  getByToken: (token, callback) ->
    return callback null, @userHash[token]

  add: (deviceId, profile, callback) ->

    return if @wait () =>
      @add deviceId, profile, callback

    debug 'Adding device ' + deviceId
    debug profile

    if not (profile.id? and profile.secret? and profile.name?)
      return callback new Error('Invalid device profile parameters')

    newProfile = Object.assign {}, profile

    @db.put 'devices', newProfile, (err, item) =>
      debug item
      return callback err if err
      callback null, item
