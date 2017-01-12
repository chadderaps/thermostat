express = require 'express'
path = require 'path'
favicon = require 'serve-favicon'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
thermostat = require './lib/thermostat'

index = require './routes/index'
users = require './routes/users'

passport = require 'passport'
Strategy = (require 'passport-google-oauth20').Strategy

console.log require 'passport-google-oauth20'

# database
#mongo = require 'mongodb'
#monk = require 'monk'
#db = monk 'localhost:27017/nodetest2'

console.log process.env.CLIENT_ID
console.log process.env.CLIENT_SECRET

passport.use(new Strategy({
  clientID: process.env.CLIENT_ID,
  clientSecret: process.env.CLIENT_SECRET,
  callbackURL: 'http://localhost:3000/login/google/callback'
  },
  (accessToken, refreshToken, profile, cb) =>
    console.log "Got key from google"
    return cb null, profile
))

passport.serializeUser( (user, cb) =>
  console.log 'ser'
  cb null, user
)

passport.deserializeUser( (obj, cb) =>
  console.log 'des'
  cb null, obj
)

app = express();

thermo = new thermostat()

# view engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'

# uncomment after placing your favicon in /public
#app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: false })
app.use cookieParser()
app.use express.static(path.join(__dirname, 'public'))
app.use(require('express-session')({ secret: 'keyboard cat', resave: true, saveUninitialized: true }));

app.use passport.initialize()
app.use passport.session()

app.use (req, res, next) =>
  req.thermostat = thermo
  next()

app.use '/', index
app.use '/users', users

# catch 404 and forward to error handler
app.use (req, res, next) =>
  err = new Error 'Not Found'
  err.status = 404
  next err

# error handler
app.use (err, req, res, next) =>
  # set locals, only providing error in development
  console.log 'Got Error'
  console.log err.message
  console.log err.stack
  console.log "Error from url " + req.originalUrl
  res.locals.message = err.message
  res.locals.error = req.app.get('env') is 'development' ? err : {}

  # render the error page
  res.status err.status or 500
  res.render 'error'

module.exports = app;
