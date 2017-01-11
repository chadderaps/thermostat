
if not process.env.DUMMY_LCD?
  LCDPlate = (require 'adafruit-i2c-lcd').plate
else
  class LCDPlate
    constructor: (id, loc) ->

    message: (msg, clear) ->
      console.log msg

module.exports =
class ThermostatLCD

    constructor: (thermostat) ->
        @lcd = new LCDPlate(1, 0x20)
        @CUR_PAT = 'AAA'
        @SET_PAT = 'BBB'
        @STATUS_PAT = 'CCC'
        @line1 = @CUR_PAT + " ".repeat(15-@CUR_PAT.length - @SET_PAT.length) + @SET_PAT
        @line2 = @STATUS_PAT + " ".repeat 15-@STATUS_PAT.length

        thermostat.onDidChange =>
          @update thermostat

    insert: (base, pat, str, just) ->
        len = str.length
        count = pat.length
        if count > len
          pad = " ".repeat count - len
          str = pad + str if just == 'right'
          str = str + pad if just == 'left'

        base = base.replace pat, str

        console.log "+++ #{base}"

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
