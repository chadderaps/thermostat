express = require 'express'
debug = (require 'debug')('thermostat:router')
router = express.Router()
passport = require 'passport'

debug "Initialized Thermostat router"

authenticationMiddleware = () =>
  return (req, res, next) ->
    if req.isAuthenticated() or true
      return next()
    else
      res.sendStatus 400

router.use (req, res, next) ->
  debug "Handling req for #{req.url}"
  next()

# GET home page.
router.get '/', authenticationMiddleware(), (req, res, next) =>
  debug "Did I do this?"
  thermo = req.thermostat
  curTemp = thermo.curTemp
  res.render 'index', { title: 'Express', thermometer: thermo, user: req.user}

router.get '/currentTemp', authenticationMiddleware(), (req, res, next) =>
  thermo = req.thermostat

  thermo.onDidChange () =>
    req.db.log thermo
    res.json JSON.stringify thermo

router.post '/changeTemp', authenticationMiddleware(), (req, res, next) =>
  thermo = req.thermostat
  method = req.body.direction

  debug req.headers
  debug req.body
  debug req.get 'content-type'

  debug "Changing temperature with method " + method

  status = thermo.increaseTemp() if method is 'increase'
  status = thermo.decreaseTemp() if method is 'decrease'

  req.db.saveConfig thermo
  req.db.getConfig (data) =>
    debug 'Got the data'

  res.sendStatus(200)

module.exports = router;
