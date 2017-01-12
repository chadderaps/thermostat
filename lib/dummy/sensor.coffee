debug = (require 'debug')('thermostat')

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

module.exports = new DummySensor()
