sensor = require 'ds18b20-raspi'

module.exports =
class Thermostat

  constructor: () ->
    console.log 'Created'
    @minTemp = 35
    @tempThreshold = 0
    setInterval @readTemp.bind(@), 1000

  readTemp: () ->
    sensor.readSimpleF @setTemp.bind(@)
    return

  setTemp: (err, temp) ->
    throw err if err
    @curTemp = temp
    @checkTemp()
    return


  setTriggerTemp: (temp) ->
    @minTemp = temp
    @checkTemp()
    return

  checkTemp: () ->
    @status = (@curTemp + @tempThreshold) < @minTemp

  On: () ->
    return @status
