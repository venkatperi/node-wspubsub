WebSocket = require 'ws'
WebSocketServer = WebSocket.Server
Channel = require "./Channel"
Log = require("node-log")(__filename)

module.exports = class WSPubSub

  constructor : ( opts = {} ) ->
    opts.path = "/" unless opts.path?
    opts.host = "localhost" unless opts.host?
    @channels = {}
    for p in ["host", "port", "path"]
      @[p] = opts[p] 
      throw new Error "missing option: #{p}" unless @[p]?

    @url = "ws://#{@host}:#{@port}#{@path}"

  start : =>
    Log.i "starting wspubsub server at: #{@url}"
    @server = new WebSocketServer host: @host, port: @port, path: @path

    @server.on "connection", (conn) =>
      Log.d "got connection: #{conn}"

      conn.on "message", (message) =>
        try
          @handle conn, message
        catch err
          Log.e "error: #{err}"

  stop: =>
    Log.i "stopping wspubsub server"
    @server.close()
    @server = {}

  handle: (conn, message) =>
    Log.d "got command: #{message}"

    message = JSON.parse message if typeof(message) == "string"
    unless message.command?
      throw new Error "missing command: #{JSON.stringify message}"

    message.command = message.command.toUpperCase()
    handler = @["__#{message.command}"]
    throw new Error "bad command: #{message.command}" unless handler?
    handler conn, message

  __SUBSCRIBE: (conn, message) =>
    throw new Error "#{message.command} command has no channels" unless message.channels?.length > 0
    @channel(c).subscribe conn for c in message.channels

  __UNSUBSCRIBE: (conn, message) =>
    throw new Error "#{message.command} command has no channels" unless message.channels?.length > 0
    @channel(c).unsubscribe conn for c in message.channels

  __PUBLISH: (conn, message) =>
    throw new Error "#{message.command}: missing channel" unless message.channel?
    @channel(message.channel).publish message.message

  channel: (name) =>
    @channels[name] = new Channel name: name unless @channels[name]?
    @channels[name]
