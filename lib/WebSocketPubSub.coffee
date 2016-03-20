conf = require "./conf"
WebSocket = require 'ws'
WebSocketServer = WebSocket.Server

module.exports = class WebSocketPubSub
  constructor : ( opts = {} ) ->
    @host = opts.host or conf.get "host" 
    @port = opts.port or conf.get "port"
    @path = opts.path or conf.get "path"
    @connections = []
    @subscriptions = {}

  start : =>
    @url = "ws://#{@host}:#{@port}#{@path}"
    console.log "starting Websocket pubsub server at: #{@url}"
    @server = new WebSocketServer host: @host, port: @port, path: @path

    @server.on "connection", (conn) =>
      @connections.push conn
      conn.on "close", =>
        idx = @connections.indexOf conn
        @connections.splice(idx, 1) unless idx == -1
        
      conn.on "message", (message) => @handle conn, message

  stop: =>
    @subscriptions = {}
    c.close() for c in @connections
    @server.close()
    @server = null
    
  handle: (conn, message) =>
    return unless @server

    message = JSON.parse message if typeof(message) == "string"
    unless message.command?
      console.log "message has no command #{message}" 
      return
    
    message.command = message.command.toUpperCase()
    handler = @["__#{message.command}"]
    unless handler?
      console.log "bad command: #{message.command}" 
      return
    handler conn, message
    
  __SUBSCRIBE: (conn, message) =>
    unless message.channels?.length > 0
      console.log "#{message.command} command has no channels"
      return
      
    for c in message.channels
      @subscriptions[c] = [] unless @subscriptions[c]?
      @subscriptions[c].push conn unless @subscriptions[c].indexOf(conn) >= 0
      
  __UNSUBSCRIBE: (conn, message) =>
    unless message.channels?.length > 0
      console.log "#{message.command} command has no channels"
      return
      
    for c in message.channels
      return unless @subscriptions[c]?
      idx = @subscriptions[c].indexOf(conn)
      @subscriptions[c].splice(idx, 1) unless idx < 0
   
  __PUBLISH: (conn, message) =>
    unless message.channel? 
      console.log "#{message.command}: missing channel"
      return
      
    data = message.message
    opts = {}
    unless typeof(data) == "string"
      opts.binary = true
      opts.mask = true

    return unless @subscriptions[message.channel]?
    c.send data, opts for c in @subscriptions[message.channel]
