debug = (require 'debug')('thermostat')

if debug.enabled
  debug 'Running Fake Version of Thermostat'
  class DummySensor
    constructor: () ->
      return

    readSimpleF: (digits, cb) ->
      if typeof digits == 'function'
        cb = digits
        digits = 2
      cb null, 35.12

  sensor = new DummySensor()
else
  sensor = require 'ds18b20-raspi'

gpio = require 'rpi-gpio'

module.exports =
class Thermostat

  constructor: () ->
    @heaterGPIO = { id: 0, init: false }
    @minTemp = 35
    @tempThreshold = 0
    @setupGPIO()
    setInterval @readTemp.bind(@), 1000

  setupGPIO: () ->
    gpio.setup @heaterGPIO, gpio.DIR_OUT, (err) =>
      throw err if err
      debug "Heater gpio is setup"

  readTemp: () ->
    sensor.readSimpleF @setCurTemp.bind(@)
    return

  setCurTemp: (err, temp) ->
    throw err if err
    @curTemp = temp
    @checkTemp()
    return

  increaseTemp: () ->
    @setTemp @minTemp+1

  decreaseTemp: () ->
    @setTemp @minTemp-1

  setTemp: (temp) ->
    debug "Min Temp set to " + temp
    @minTemp = temp
    @checkTemp()
    return

  _EnableHeater: () ->
    return if not @heaterGPIO.init
    gpio.write @heaterGPIO.id, 1, (err) =>
      throw err if err
      debug "Enabled the heater"

  _disableHeater: () ->
    return if not @heaterGPIO.init
    gpio.write @heaterGPIO, 0, (err) =>
      throw err if err
      debug "Disabled the heater"

  checkTemp: () ->
    @status = (@curTemp + @tempThreshold) < @minTemp
    @_EnableHeater() if @status else @_DisableHeater()

  On: () ->
    return @status
