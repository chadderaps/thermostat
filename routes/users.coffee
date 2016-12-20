express = require 'express'
router = express.Router()

# GET users listing.
router.get '/userlist', (req, res, next) =>
  db = req.db
  collection = db.get 'userlist'
  collection.find {}, {}, (e, docs) =>
    res.json docs

module.exports = router;
