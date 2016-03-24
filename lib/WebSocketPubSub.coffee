conf = require "./conf"
WebSocket = require 'ws'
WebSocketServer = WebSocket.Server
Channel = require "./Channel"
Log = require "./Log"
TAG = Log.makeTag __filename

module.exports = class WebSocketPubSub
  
  constructor : ( opts = {} ) ->
    @channels = {}
    for p in ["host", "port", "path"]
      @[p] = opts[p] or conf.get p
      throw new Error "missing option: #{p}" unless @[p]?
      
    @url = "ws://#{@host}:#{@port}#{@path}"
       
  start : =>
    Log.i TAG, "starting wspubsub server at: #{@url}"
    @server = new WebSocketServer host: @host, port: @port, path: @path

    @server.on "connection", (conn) =>
      Log.d TAG, "got connection: #{conn}"
      
      conn.on "message", (message) =>
        try  
          @handle conn, message
        catch err
          Log.e TAG, "error: #{err}"

  stop: =>
    Log.i TAG, "stopping wspubsub server"
    @server.close()
    @server = {}
    
  handle: (conn, message) =>
    Log.d TAG, "command: #{message}"
  
    message = JSON.parse message if typeof(message) == "string"
    throw new Error "missing command: #{JSON.stringify message}" unless message.command? 
    
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
