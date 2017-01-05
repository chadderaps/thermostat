debug = (require 'debug')('thermostat')
EventEmitter = require 'events'

if debug.enabled and false
  debug 'Running Fake Version of Thermostat'
  class DummySensor
    constructor: () ->
      @curTemp = 35
      return

    readSimpleF: (digits, cb) ->
      if typeof digits == 'function'
        cb = digits
        digits = 2
      changeTemp = Math.random() * 10

      debug "Change Temp is #{changeTemp}"

      @curTemp = @curTemp + 1 if changeTemp > 9
      @curTemp = @curTemp - 1 if changeTemp < 1

      cb null, @curTemp

  sensor = new DummySensor()

  class DummyGPIO

    constructor: () ->
      return

    setup: (pin, dir, callback) ->
      debug "Setup " + pin + " with dir " + dir
      callback null

    setMode: (mode) ->
      debug "Setting mode to " + mode

    write: (pin, val, callback) ->
      debug "Writing " + val + " to " + pin
      callback null

  gpio = new DummyGPIO()

  gpio.DIR_OUT = 'OUT'
  gpio.MODE_BCM = 'BCM'
  gpio.MODE_RPI = 'RPI'

else
  sensor = require 'ds18b20-raspi'
  gpio = require 'rpi-gpio'

module.exports =
class Thermostat

  constructor: () ->
    @heaterGPIO = { id: 17, init: false }
    @minTemp = 70
    @tempThreshold = 0
    @emitter = new EventEmitter
    @setupGPIO()
    setInterval @readTemp.bind(@), 1000

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

  setCurTemp: (err, temp) ->
    throw err if err
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

    @emitter.emit 'did-change'

  On: () ->
    return @status
