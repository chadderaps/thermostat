debug = require('debug') 'thermostat:db'
#AWS = require 'aws-sdk'
DynamoDB = require './dynamo-db'
crypto = require 'crypto'

module.exports =
class ThermostatDB

  ###
  DATA_TYPES : {
    'string': 'S'
    'number': 'N'
    'boolean': 'BOOL'
    'string list': 'SS'
    'number list': 'NS'
    'item': 'L'
  }
  ###

  constructor: (thermostat = {}) ->

    @thermoID = thermostat?.ID || 'THERMOSTAT-DEV'

    dynamoOptions = {
      endpoint: 'http://server:8000'
      tables: [
        {
          id: 'config'
          name: @thermoID
          timeout: 0
          singleId: true
        }
        {
          id: 'log'
          name: @thermoID + ".LOG"
        }
      ]
    }

    @db = new DynamoDB dynamoOptions

    @initialized = false

    @db.exists 'config', (err, exists) =>
      throw err if err
      if not exists
        @db.create 'config', (err, data) =>
          throw err if err
      @db.wait 'config', (err, data) =>
        throw err if err
        @db.exists 'log', (err, exists) =>
          throw err if err
          if not exists
            @db.create 'log', (err, data) =>
              debug "Created Log"
          @db.wait 'log', (err, data) =>
            throw err if err
            @init()

  init: () ->

    @initialized = true

    if debug.enabled
      @db.list (err, data) =>
        if (err)
          debug "Got Error"
          debug err
        else
          debug "Got data"
          debug data

  getConfig: (callback) ->
    @db.getLatest 'config', (err, data) =>
      debug "Latest data is " + JSON.stringify data
      callback data

  saveConfig: (thermostat) ->
    @db.put 'config', {
      'set temp': thermostat.minTemp
      'threshold' : thermostat.tempThreshold
    }, (err, data) =>
      debug 'saved config'

  log: (thermostat) ->
    debug "Logging Thermostat"

    return if not @initialized

    @db.put 'log', {
      status: thermostat.status
      'current temp': thermostat.curTemp
      'set temp': thermostat.minTemp
    }, (err) =>
      throw err if err
