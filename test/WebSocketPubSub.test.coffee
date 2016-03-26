should = require( "should" )
assert = require( "assert" )
WSPubSub = require '../'
WebSocket = require "ws"

server = {}

describe "WSPubSub", ->
  
#  beforeEach ->
#    client1.close() if client1?
#    client2.close() if client2?
  
  it "start the server", ->
    server = new WSPubSub( )
    server.start()

  it "client 1 can subscribe to a channel", ( done ) ->
    client1 = new WebSocket server.url
    client1.on "open", ->
      data = command : "subscribe", channels : [ "test" ]
      client1.send JSON.stringify( data )
      client1.close()
      done()

  it "client 1 can set a name", ( done ) ->
    client1 = new WebSocket server.url
    client1.on "open", ->
      client1.send JSON.stringify( command: "setname", name: "client1" )
      client1.send JSON.stringify( command: "subscribe", channels: ["test"] )
      client1.close()
      done()

  it "client 2 can publish to the same channel and client 1 will receive the message", ( done ) ->
    message = "this is a test"

    client1 = new WebSocket server.url
    client1.on "open", ->
      client1.send JSON.stringify( command: "subscribe", channels: ["test"] )

      client1.on "message", ( msg ) ->
        msg = JSON.parse msg
        msg.channel.should.equal "TEST"
        msg.message.should.equal message
        client1.close()
        done()

      client2 = new WebSocket server.url
      client2.on "open", ->
        client2.send JSON.stringify( command: "publish", channel: "test", message: message )

#  it "client 2 publishes again, but no one receives the message ", ( done ) ->
#    message = "this is a test"
#
#    client1.on "message", ( msg ) ->
#      msg.should.not.equal message
#      done()
#
#    data = command : "publish", channel : "test", message : message
#    client2.send JSON.stringify( data )
#    setTimeout done, 1000

  it "stop the server", ->
    server.stop()
#