EventEmitter = require( "events" ).EventEmitter
Q = require 'q'
Queue = require "node-observable-queue"
WebSocket = require "ws"
Log = require( "yandlr" )( module: module )
conf = require "./conf"

module.exports = class WSPubSubClient extends EventEmitter

  constructor : ( {
  @url, @ws, @name,
  @autoReconnect = conf.get( "wspubsub.client.autoReconnect" ),
  @queueIncoming = conf.get( "wspubsub.client.queueIncoming" ),
  @queueOutgoing = conf.get( "wspubsub.client.queueOutgoing" ),
  @timeout = conf.get( "wspubsub.client.timeout" )
  } ) ->
    throw new Error "either url or connection must be defined, not both" if (@url? && @ws?) or (!@url? and !@ws?)
    throwError "missing name" unless @name?

    @Log = require( "yandlr" )( module:module)
    @Log.TAG = "#{@Log.TAG} #{@name}"

    @outgoingQueue = new Queue()
    @incomingQueue = new Queue()

    defer = Q.defer()

    if @url || @ws?.readyState != 1
      @ws = new WebSocket @url if @url?
      @ws.on "open", =>
        defer.resolve Q( @ws )
    else
      defer.resolve Q( @ws )

    defer.promise.then @onOpen

  onOpen : =>
    @Log.i "open"

    @setName @name
    @ws.on "message", ( msg ) =>
      @Log.d "received: #{msg}"
      msg = JSON.parse msg
      @incomingQueue.enqueue msg if @queueIncoming?
      @emit 'message', msg

    @ws.on "error", ( err ) =>
      @Log.e "#{JSON.stringify err}"
      @reconnect() if @autoReconnect

    @ws.on "close", =>
      @Log.i "closed"
      @reconnect() if @autoReconnect

    @outgoingQueue.on "enqueue", @processOutgoingQueue

    @processOutgoingQueue()

    @emit 'open'

  processOutgoingQueue : =>
    while msg = @outgoingQueue.dequeue()
      do ( msg ) =>
        msg = JSON.stringify( msg )
        @Log.d "sending queued msg: #{msg}"
        @ws.send msg

  reconnect : =>
    @Log.i "reconnecting in #{@timeout} ms"
    @ws = {}
    setTimeout @startWebSocket, @timeout

  send : ( msg ) =>
#    @Log.d "send: #{msg}"
    if @queueOutgoing
      @outgoingQueue.enqueue msg
    else
      @ws.send JSON.stringify( msg )

  close : =>
    @Log.i "close()"
    @autoReconnect = false
    @ws.close()
    @ws = undefined

  subscribe : ( channels... ) =>
    @Log.d "subscribe: #{channels}"
    msg = command : "subscribe", channels : channels
    @send msg

  unsubscribe : ( channels... ) =>
    @Log.d "unsubscribe: #{channels}"
    msg = command : "unsubscribe", channels : channels
    @send msg

  publish : ( channel, message ) =>
    @Log.d "publish: #{channel} - #{message}"
    msg = command : "publish", channel : channel, message : message
    @send msg

  setName : ( name ) =>
    @Log.d "setName: #{name}"
    msg = command : "setname", name : name
    @send msg
