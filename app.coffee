debug = (require 'debug') 'thermostat:express'
cson = require 'cson'
express = require 'express'
path = require 'path'
favicon = require 'serve-favicon'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
thermostat = require './lib/thermostat'
thermostatDb = require './lib/thermostat-db'
UsersDb = require './lib/Users'

oauthkeys = cson.requireCSONFile './private/oauth.cson'

index = require './routes/index'
thermostatroute = require './routes/thermostat'
users = require './routes/users'

passport = require 'passport'
GoogleStrategy = (require 'passport-google-oauth20').Strategy
BearerStrategy = (require 'passport-http-bearer').Strategy

# database
#mongo = require 'mongodb'
#monk = require 'monk'
#db = monk 'localhost:27017/nodetest2'

usersDb = new UsersDb()

passport.use(new GoogleStrategy({
  clientID: oauthkeys.google.CLIENT_ID,
  clientSecret: oauthkeys.google.CLIENT_SECRET,
  callbackURL: oauthkeys.google.CALLBACK_URL
  },
  (accessToken, refreshToken, profile, cb) =>
    console.log "Got key from google - " + JSON.stringify profile
    console.log " with token " + JSON.stringify accessToken
    usersDb.get profile.id, (user) =>
      if user?
        return cb null, user
      else
        usersDb.add profile.id, profile, (user) =>
          return cb null, user
  ))

passport.use(new BearerStrategy(
    (token, cb) =>
      debug "I got a bearer strategy request with #{token}"
      usersDb.getUserByToken token, (err, user) =>
        debug "User is #{user}"
        debug usersDb.userHash
        return cb err, null if err
        return cb null, user?
  ))

passport.serializeUser( (user, cb) =>
  debug 'Serialize'
  cb null, user.id
)

passport.deserializeUser( (id, cb) =>
  debug 'Deserialize'
  usersDb.getUserById id, (user) =>
    cb null, user
)

app = express();

if process.env.THERMOSTAT_SERVER == '1'
  thermo = {}
else
  thermo = new thermostat()

db = new thermostatDb thermo

#db.getConfig (config) =>
#  thermo.setConfig config

# view engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'

# uncomment after placing your favicon in /public
#app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use logger('dev')
app.use (req, res, next) =>
  req.rawBody = ''
  req.on 'data', (chunk) =>
    req.rawBody += chunk
  next()
app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: false })
app.use cookieParser()
app.use express.static(path.join(__dirname, 'public'))
app.use(require('express-session')({ secret: 'keyboard cat', resave: true, saveUninitialized: true }));

app.use passport.initialize()
app.use (req, res, next) =>
  console.log JSON.stringify req.session
  passport.session()(req, res, next)

app.use (req, res, next) =>
  req.thermostat = thermo
  req.db = db
  next()

app.connections = {};

handleSocket = (socket) =>
  console.log 'User is ' + JSON.stringify socket.request.session
  socket.on 'temperature', (username) =>
    app.connections[username] = socket

app.chadCreateSocket = (io) =>
  app.io = io
  sessionMiddlware = require('express-session')({ secret: 'keyboard cat', resave: true, saveUninitialized: true })
  passportSessionMiddlware = passport.session()

  app.io.use (socket, next) =>
    console.log 'Session'
    sessionMiddlware socket.request, {}, next
  app.io.use (socket, next) =>
    console.log 'Passport'
    console.log JSON.stringify socket.request.session
    passportSessionMiddlware socket.request, {}, next
  app.io.sockets.on 'connection', handleSocket

console.log "Thermo server is #{process.env.THERMOSTAT_SERVER}"

if process.env.THERMOSTAT_SERVER == '1'
  console.log 'Running thermostat server'
  app.use '/', index
  app.use '/users', users
  app.use '/device', require './routes/devices'

  app.post '/message/:action/:to', (req, res) =>
    debug req.params.to
    debug app.connections
    target = app.connections[req.params.to]
    if target?
      target.emit(req.params.action, req.body)
      res.send 200
    else
      res.send 404

else
  console.log 'Running just the thermostat'
  app.use '/thermostat', thermostatroute


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
