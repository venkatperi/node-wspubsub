Log = require("node-log")(__filename)
Log.level = "debug"

module.exports = class Channel

  constructor : ( {@name, @retain = 10} ) ->
    throw new Error "name missing" unless @name?
    @name = @name.toUpperCase()
    Log.i "creating channel: #{@name}"

    @subscriptions = new Set()
    @recent = []

  subscribe : ( connection ) =>
    Log.d "subscribe[#{@name}]: #{connection}"

    @subscriptions.add connection
    connection.on "close", => @unsubscribe connection
    @send connection, message for message in @recent

  unsubscribe : ( connection ) =>
    Log.d "unsubscribe[#{@name}]: #{connection}"
    @subscriptions.delete connection

  send : ( connection, message ) =>
    message = JSON.stringify message unless typeof(message) == "string"
    connection.send message

  sendAll : ( message ) =>
    @subscriptions.forEach ( conn ) =>
      @send conn, message

  publish : ( message ) =>
    Log.d "publishing on #{@name}: #{message}"
    data = channel : @name, message : message

    if @retain?
      @recent.push data
      @recent.splice( 0, 1 ) if @recent.length > @retain

    @sendAll data
