express = require 'express'
debug = (require 'debug')('thermometer')
router = express.Router()

debug "Initialized Index router"

# GET home page.
router.get '/', (req, res, next) =>
  thermo = req.thermostat
  curTemp = thermo.curTemp
  res.render 'index', { title: 'Express', thermometer: thermo}

router.get '/thermometer', (req, res, next) =>
  thermo = req.thermostat

  thermo.onDidChange () =>
    res.json JSON.stringify thermo

router.post '/thermometer/changeTemp', (req, res, next) =>
  thermo = req.thermostat
  method = req.body.direction

  debug "Changing temperature with method " + method

  status = thermo.increaseTemp() if method is 'increase'
  status = thermo.decreaseTemp() if method is 'decrease'

  res.sendStatus(200)

module.exports = router;
