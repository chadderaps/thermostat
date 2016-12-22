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
      cb null, 35

  sensor = new DummySensor()
else
  sensor = require 'ds18b20-raspi'


module.exports =
class Thermostat

  constructor: () ->
    @minTemp = 35
    @tempThreshold = 0
    setInterval @readTemp.bind(@), 1000

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

  checkTemp: () ->
    @status = (@curTemp + @tempThreshold) < @minTemp

  On: () ->
    return @status
