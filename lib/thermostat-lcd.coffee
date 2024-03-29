debug = (require 'debug')('thermostat')

if not process.env.DUMMY_LCD?
  LCDPlate = (require 'adafruit-i2c-lcd').plate
else
  class LCDPlate
    constructor: (id, loc) ->
      @colors = {On: 1}

    message: (msg, clear) ->
      debug msg

    backlight: (color) ->

    createChar: (id, spec) ->

    on: (event, callback) ->



module.exports =
class ThermostatLCD

    constructor: (thermostat) ->
        @lcd = new LCDPlate(1, 0x20)
        @lcd.backlight @lcd.colors.ON
        @lcd.createChar 1, [28,20,28,0,0,0,0]

        @degreeSymbol =  if process.env.DUMMY_LCD? then '\xB0' else'\x01'

        @CUR_PAT = 'AA'
        @SET_PAT = 'BB'
        @STATUS_PAT = 'CCC'
        @line1 = @CUR_PAT + @degreeSymbol + " ".repeat(14-@CUR_PAT.length - @SET_PAT.length) + @SET_PAT + @degreeSymbol
        @line2 = @STATUS_PAT + " ".repeat 16-@STATUS_PAT.length

        thermostat.onDidChange =>
          @update thermostat

        @lcd.on 'button_up', (button) =>
            @buttonReleased thermostat, button

    buttonReleased: (thermostat, button) ->
        thermostat.increaseTemp() if button == @lcd.buttons.UP
        thermostat.decreaseTemp() if button == @lcd.buttons.DOWN

    insert: (base, pat, str, just) ->
        len = str.length
        count = pat.length
        if count > len
          pad = " ".repeat count - len
          str = pad + str if just == 'right'
          str = str + pad if just == 'left'

        base = base.replace pat, str

        debug "+++ #{base}"

        return base

    update: (thermostat) ->
        curTemp = thermostat.curTemp
        setTemp = thermostat.minTemp
        if thermostat.On()
            isOn = 'On'
        else
            isOn = 'Off'

        tempLine = @insert @line1, @CUR_PAT, curTemp.toString(), 'left'
        tempLine = @insert tempLine, @SET_PAT, setTemp.toString(), 'right'
        statusLine = @insert @line2, @STATUS_PAT, isOn, 'left'

        @lcd.message tempLine + '\n' + statusLine, true

        thermostat.onDidChange =>
          @update thermostat
