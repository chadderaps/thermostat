debug = (require 'debug')('thermostat:control')
EventEmitter = require 'events'
LCD = require './thermostat-lcd'

if process.env.DUMMY_THERMOSTAT?
  debug 'Running Fake Version of Thermostat'
  sensor = require './dummy/sensor'
  console.log sensor
  gpio = require './dummy/gpio'
  console.log gpio
else
  sensor = require 'ds18b20-raspi'
  gpio = require 'rpi-gpio'

module.exports =
class Thermostat

  constructor: () ->
    @heaterGPIO = { id: 17, init: false }
    @minTemp = if debug.enabled then 35 else 70
    @tempThreshold = 0
    @emitter = new EventEmitter
    @setupGPIO()
    setInterval @readTemp.bind(@), 1000
    @lcd = new LCD(@)

  setConfig: (config) ->
    debug 'Setting Config'

  setupGPIO: () ->
    gpio.setMode gpio.MODE_BCM
    gpio.setup @heaterGPIO.id, gpio.DIR_OUT, (err) =>
      throw err if err
      @heaterGPIO.init = true
      debug "Heater gpio is setup"

  readTemp: () ->
    sensor.readSimpleF @setCurTemp.bind(@)
    return

  onDidChange: (callback) ->
    debug "Waiting for a change"
    @emitter.once 'did-change', callback

  onStatusChange: (callback) ->
    debug "Waiting for a status change"
    @emitter.on 'did-change-status', callback

  setCurTemp: (err, temp) ->
    throw err if err
    temp = Math.round(temp, 0)
    update = temp != @curTemp
    @curTemp = temp
    @checkTemp() if update
    return

  addWaiter: (waiter) ->

  increaseTemp: () ->
    @setTemp @minTemp+1

  decreaseTemp: () ->
    @setTemp @minTemp-1

  setTemp: (temp) ->
    debug "Min Temp set to " + temp
    update = temp != @minTemp
    @minTemp = temp
    @checkTemp() if update
    return

  _EnableHeater: () ->
    return if not @heaterGPIO.init
    gpio.write @heaterGPIO.id, 1, (err) =>
      throw err if err
      debug "Enabled the heater"

  _DisableHeater: () ->
    return if not @heaterGPIO.init
    gpio.write @heaterGPIO.id, 0, (err) =>
      throw err if err
      debug "Disabled the heater"

  checkTemp: () ->
    old_status = @status
    @status = (@curTemp + @tempThreshold) < @minTemp
    if @status
      @_EnableHeater()
    else
      @_DisableHeater()

    debug "Did Change"

    @emitter.emit 'did-change', @
    @emitter.emit 'did-change-status', @ if old_status != @status

  On: () ->
    return @status
