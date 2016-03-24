winston = require( "winston" )
path = require 'path'
moment = require 'moment'
strRight = require "underscore.string/strRight"
strLeft = require "underscore.string/strLeft"
conf = require "./conf"

class Log
  basePath : path.dirname __filename

  constructor : ( options = {} ) ->
    transports = [ new winston.transports.Console ]
    @logger = new winston.Logger
      transports : transports
      level: conf.get "logger:level" or "info"

  makeTag : ( filename ) =>
    dir = path.dirname filename
    tag = path.join dir, path.basename( filename, '.coffee' )
    tag = strRight tag, @basePath
    strRight tag, '/'

  log : ( level, TAG, msg, meta ) => @logger.log level, "[#{TAG}] #{msg}", meta
  v : ( TAG, msg, meta ) => @log 'verbose', TAG, msg, meta
  d : ( TAG, msg, meta ) => @log 'debug', TAG, msg, meta
  i : ( TAG, msg, meta ) => @log 'info', TAG, msg, meta
  e : ( TAG, msg, meta ) => @log 'error', TAG, msg, meta
  w : ( TAG, msg, meta ) => @log 'warn', TAG, msg, meta
  f : ( TAG, msg, meta ) => @log 'fatal', TAG, msg, meta

winston.transports.Console.prototype.log = ( level, msg, meta, callback ) ->
  return callback( null, true )  if @silent
  self = this
  l = level.substr( 0, 1 ).toUpperCase()
  ts = moment().format(  "MM-DD-HH:mm:ss:SSS" )
  msg = strLeft msg, "undefined"
  output = [ "#{l}/#{ts} #{msg}" ]

  # if config.get "logger:logMeta"
    # output.push "#{JSON.stringify( meta, null, 2 )}" if meta? and not _.isEmpty meta

  output = output.join '\n'
  console.log output

  self.emit "logged"
  callback null, true

module.exports = exports = new Log()


