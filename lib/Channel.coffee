conf = require "./conf"

module.exports = class Channel

  constructor : ( {@name, @retain} ) ->
    throw new Error "name missing" unless @name?
    @name = @name.toUpperCase()
    @Log = require( "yandlr" )( module : module, postfix : @name )
    @Log.i "creating channel"

    @retain = conf.get "wspubsub:channel:retain" unless @retain
    @subscriptions = new Set()
    @recent = []

  subscribe : ( connection ) =>
    @Log.d "subscribe #{connection.__name}"

    @subscriptions.add connection
    connection.on "close", =>
      @Log.d "closed #{connection.__name}"
      @unsubscribe connection
    @send connection, message for message in @recent

  unsubscribe : ( connection ) =>
    @Log.d "unsubscribe #{connection.__name}"
    @subscriptions.delete connection

  send : ( connection, message ) =>
    message = JSON.stringify message unless typeof(message) == "string"
    @Log.d "send message to #{connection.__name} #{message}"
    connection.send message

  sendAll : ( message ) =>
    @Log.d "sendAll: num subscriptions: #{@subscriptions.size}"
    @subscriptions.forEach ( conn ) =>
      @send conn, message

  publish : ( message ) =>
    @Log.d "publishing: #{message}"
    data = channel : @name, message : message

    if @retain?
      @recent.push data
      @recent.splice( 0, 1 ) if @recent.length > @retain

    @sendAll data
