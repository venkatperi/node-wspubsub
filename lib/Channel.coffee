Log = require "./Log"
TAG = Log.makeTag __filename

module.exports = class Channel

  subscriptions: new Set()
  recent: []

  constructor: ({@name, @retain = 10} ) ->
    throw new Error "name missing" unless @name?
    @name = @name.toUpperCase()
    Log.i TAG, "creating channel: #{@name}"

  subscribe: (connection) =>
    Log.d TAG, "subscribe[#{@name}]: #{connection}"

    @subscriptions.add connection

    connection.on "close", => @unsubscribe connection

    #send any recent messages
    for message in @recent
      message = JSON.stringify message unless typeof(message) == "string"
      connection.send message

  unsubscribe: (connection) =>
    Log.d TAG, "unsubscribe[#{@name}]: #{connection}"
    @subscriptions.delete connection

  sendAll: (message) =>
    message = JSON.stringify message unless typeof(message) == "string"
    @subscriptions.forEach (conn) =>
      conn.send message

  publish: (message) =>
    Log.d TAG, "publishing on #{@name}: #{message}"
    data = channel: @name, message: message

    if @retain?
      @recent.push data
      @recent.splice(0,1) if @recent.length > @retain

    @sendAll data
