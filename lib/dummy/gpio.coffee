debug = (require 'debug')('thermostat')

class DummyGPIO

  constructor: () ->
    @DIR_OUT = 'OUT'
    @MODE_BCM = 'BCM'
    @MODE_RPI = 'RPI'
    return

  setup: (pin, dir, callback) ->
    debug "Setup " + pin + " with dir " + dir
    callback null

  setMode: (mode) ->
    debug "Setting mode to " + mode

  write: (pin, val, callback) ->
    debug "Writing " + val + " to " + pin
    callback null

module.exports = new DummyGPIO()
