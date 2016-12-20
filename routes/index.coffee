express = require 'express'
router = express.Router()

# GET home page.
router.get '/', (req, res, next) =>
  thermo = req.thermostat
  curTemp = thermo.curTemp
  res.render 'index', { title: 'Express', thermometer: thermo}

router.get '/thermometer', (req, res, next) =>
  thermo = req.thermostat
  res.json JSON.stringify thermo

router.post '/toggle', (req, res) =>
  res.redirect 'back'

module.exports = router;
