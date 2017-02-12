express = require 'express'
debug = (require 'debug')('thermostat:redirect')
router = express.Router()
passport = require 'passport'

debug "Initialized Index router"

authenticationMiddleware = () =>
  return (req, res, next) ->
    if req.isAuthenticated()
      debug req.headers
      debug req.session.id
      debug req.session.cookie
      return next()
    else
      debug req.headers
      debug req.session.id
      debug req.session.cookie
      res.redirect '/login'

thermoRequest = (thermo, req, res) ->
  debug "Creating request to #{thermo.uri}"

  if thermo.json
    if typeof req.body == 'object'
      body = req.body
    else
      body = JSON.parse req.body
  else
    body = JSON.stringify req.body

  params = {
    uri: thermo.uri + req.path
    json: thermo.json ? false
    headers: req.headers
    body: body
    method: req.method
  }

  delete params.headers.host

  request params, (err, remRes, remBody) =>
    debug "Completed request"
    debug err
    return res.sendStatus 500 if err
    res.writeHead
    res.end remBody
    debug res

# GET home page.
router.get '/', authenticationMiddleware(), (req, res, next) =>
  thermo = req.thermostat
  curTemp = thermo.curTemp
  res.render 'index', { title: 'Express', thermometer: thermo, user: req.user}

router.get '/login', (req, res, next) =>
  res.render 'login', { }

router.get '/login/google',
  passport.authenticate 'google', {scope: ['profile']}

router.get '/login/google/callback',
  passport.authenticate 'google', {
    failureRedirect: '/',
    successRedirect: '/'
  }

router.get '/thermostat/currentTemp', authenticationMiddleware(), (req, res, next) =>
  debug "Redirecting get current temp"
  thermoRequest {uri: 'http://localhost:3001'}, req, res

router.post '/thermostat/changeTemp', authenticationMiddleware(), (req, res, next) =>
  debug "Redirecting change temp"
  #res.redirect 307, 'http://localhost:3001/thermostat/changeTemp'
  thermoRequest { uri: 'http://localhost:3001', json: true}, req, res

module.exports = router;
