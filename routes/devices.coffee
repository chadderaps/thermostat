express = require 'express'
router = express.Router()
Devices = require '../lib/controllers/devices'

router.post '/register/:deviceid', Devices.isAuthenticated, Devices.add

router.get '/callin/:deviceid', Devices.isAuthenticated, Devices.get

router.get '/list', Devices.isAuthenticated, Devices.get

module.exports = router
