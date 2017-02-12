debug = (require 'debug')('thermostat:deviceAuth')
BasicStrategy = (require 'passport-http').BasicStrategy
request = require 'request'
DevicesDb = require '../devices-db'
passport = require 'passport'

devicesDb = new DevicesDb()

exports = {}

passport.use('device-basic', new BasicStrategy(
  (deviceId, password, callback) =>
    debug 'Authorizing ' + deviceId
    devicesDb.get deviceId, (err, device) =>
      return callback err if err

      debug "#{password} should match #{device.secret}"
      if device? and device.secret == password
        return callback null, device

      return callback null, false
))

exports.isAuthenticated = passport.authenticate('device-basic', {session: false})
exports.add = (req, res) =>
  params = {
    id : req.params.deviceid
    secret : req.body.secret
    name : req.body.name
  }

  devicesDb.add params.id, params, (err, item) =>
    return res.sendStatus 400 if err
    return res.sendStatus 200

exports.get = (req, res) =>
  debug "Got a callin message from #{req.params.deviceid}"
  res.sendStatus 200

exports.list = (req, res) =>
  devicesDb.list (err, items) =>
    res.json(items)
    res.end()

module.exports = exports
