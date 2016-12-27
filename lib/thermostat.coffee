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
    @heaterGPIO = 0
    @minTemp = 35
    @tempThreshold = 0
    setInterval @readTemp.bind(@), 1000

  setupGPIO: () ->
    gpio.setup @heaterGPIO, gpio.DIR_OUT, (err) =>
      throw err if err
      console.log "Heater gpio is setup"

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
    gpio.write @heaterGPIO, 1, (err) =>
      throw err if err
      console.log "Enabled the heater"

  _disableHeater: () ->
    gpio.write @heaterGPIO, 0, (err) =>
      throw err if err
      console.log "Disabled the heater"

  checkTemp: () ->
    @status = (@curTemp + @tempThreshold) < @minTemp
    @_EnableHeater() if @status else @_DisableHeater()

  On: () ->
    return @status
