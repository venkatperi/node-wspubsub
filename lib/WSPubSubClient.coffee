EventEmitter = require("events").EventEmitter
ws = require "ws"
Q = require 'q'
Queue = require "./Queue"
WebSocket = require "ws"
Log = require "./Log"
TAG = Log.makeTag __filename

module.exports = class WSPubSubClient extends EventEmitter
  
  constructor: ({@url, @ws, @name, @autoReconnect = true, @queueIncoming = true, @queueOutgoing = true}) ->
    throw new Error "either url or connection must be defined, not both" if @url? && @ws?
    throw new Error "missing name" unless @name?
    
    @TAG = "#{TAG} #{@name}"
    @outgoingQueue = new Queue()
    @incomingQueue = new Queue()
    
    defer = Q.defer()
    
    if @url || @ws.readyState != 1
      @ws = new WebSocket @url if @url?
      @ws.on "open", =>
        defer.resolve Q(@ws)
    else        
      defer.resolve Q(@ws)
      
    defer.promise.then @onOpen
    
  onOpen: =>
    Log.i @TAG, "open"
    
    @ws.on "message", (msg) =>
      Log.d @TAG, "received: #{msg}"
      msg = JSON.parse msg
      @incomingQueue.enqueue msg if @queueIncoming?
      @emit 'message', msg
    
    @ws.on "error", (err) => 
      Log.e @TAG, "#{JSON.stringify err}"
      @reconnect() if @autoReconnect

    @ws.on "close", =>
      Log.i @TAG, "closed"
      @reconnect() if @autoReconnect

    @outgoingQueue.on "enqueue", @processOutgoingQueue
    
    @processOutgoingQueue()
    
    @emit 'open'
      
  processOutgoingQueue: =>
    while msg = @outgoingQueue.dequeue()
      msg = JSON.stringify(msg) 
      Log.d @TAG, "sending queued msg: #{msg}"
      @ws.send msg
      
  reconnect: =>
    Log.i @TAG, "reconnecting in #{@timeout} ms"
    @ws = {}
    setTimeout => @startWebSocket(),
    @timeout
    
  send: (msg) =>
    Log.d @TAG, "send: #{msg}"  
    if @queueOutgoing    
      @outgoingQueue.enqueue msg
    else
      @ws.send JSON.stringify(msg) 
      
  close: =>
    Log.i @TAG, "close()"
    @autoReconnect = false
    @ws.close()
    @ws = undefined
    
  subscribe: (channels...) =>
    Log.d @TAG, "subscribe: #{channels}"  
    msg = command: "subscribe", channels: channels
    @send msg 
      
  unsubscribe: (channels...) =>
    Log.d @TAG, "unsubscribe: #{channels}"  
    msg = command: "unsubscribe", channels: channels
    @send msg 
    
  publish: (channel, message) =>
    Log.d @TAG, "publish: #{channel} - #{message}"  
    msg = command: "publish", channel: channel, message: message
    @send msg 
