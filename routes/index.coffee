express = require 'express'
debug = (require 'debug')('thermometer')
passport = require 'passport'
router = express.Router()

debug "Initialized Index router"

# GET home page.
router.get '/', (req, res, next) =>
  thermo = req.thermostat
  curTemp = thermo.curTemp
  res.render 'index', { title: 'Express', thermometer: thermo, user: req.user}

router.get '/login', (req, res, next) =>
  res.render 'login', { }

router.get '/login/google', (req, res, next) =>
  console.log 'google auth'
  passport.authenticate 'google', {scope: ['profile']}

router.get '/login/google/callback', (req, res, next) =>
  passport.authenticate 'google', {failureRedirect: '/login'},
    (req, res) =>
      console.log 'callback'
      res.redirect '/'

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
