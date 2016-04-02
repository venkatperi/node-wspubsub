WebSocket = require 'ws'
WebSocketServer = WebSocket.Server
Channel = require "./Channel"
Log = require( "yandlr" ) module : module

conf = null
Log.then ->
  conf = require "./conf"
  conf.get "wspubsub:host"
  .then (x) ->
    console.log x

counter = 1

module.exports = class WSPubSub

  constructor : ( opts = {} ) ->
    @channels = {}
    @connections = new Set()

    for p in [ "host", "port", "path" ]
      @[ p ] = opts[ p ] or conf.get "wspubsub:#{p}"
      throw new Error "missing option: #{p}" unless @[ p ]?

    @url = "ws://#{@host}:#{@port}#{@path}"

  start : =>
    Log.i "starting wspubsub server at: #{@url}"
    @server = new WebSocketServer host : @host, port : @port, path : @path

    @server.on "error", ( err ) =>
      Log.e err

    @server.on "connection", ( conn ) =>
      conn.__name = "unnamed-#{counter++}"
      Log.d "[#{conn.__name}] connection opened"

      conn.on "message", ( message ) =>
        try
          @handle conn, message
        catch err
          Log.e "error: #{err}"

  stop : =>
    Log.i "stopping wspubsub server"
    @server.close()
    delete @server

  handle : ( conn, message ) =>
    Log.d "[#{conn.__name}] got command: #{message}"

    message = JSON.parse message if typeof(message) == "string"
    unless message.command?
      throw new Error "[#{conn.__name}] missing command: #{JSON.stringify message}"

    message.command = message.command.toUpperCase()
    handler = @[ "__#{message.command}" ]
    throw new Error "[#{conn.__name}] bad command: #{message.command}" unless handler?
    handler conn, message

  __SUBSCRIBE : ( conn, message ) =>
    throw new Error "[#{conn.__name}] #{message.command} command has no channels" unless message.channels?.length > 0
    @channel( c ).subscribe conn for c in message.channels

  __UNSUBSCRIBE : ( conn, message ) =>
    throw new Error "[#{conn.__name}] #{message.command} command has no channels" unless message.channels?.length > 0
    @channel( c ).unsubscribe conn for c in message.channels

  __PUBLISH : ( conn, message ) =>
    throw new Error "#[#{conn.__name}] {message.command}: missing channel" unless message.channel?
    @channel( message.channel ).publish message.message

  __SETNAME : ( conn, message ) =>
    throw new Error "[#{conn.__name}] #{message.command}: missing name" unless typeof message.name is "string"
    conn.__name = message.name

  channel : ( name ) =>
    name = name.toUpperCase()
    @channels[ name ] = new Channel name : name unless @channels[ name ]?
    @channels[ name ]
