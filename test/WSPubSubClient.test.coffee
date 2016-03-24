should = require( "should" )
assert = require( "assert" )
WebSocketPubSub = require '../lib/WebSocketPubSub'
WSPubSubClient = require '../lib/WSPubSubClient'
WebSocket = require "ws"

host = "localhost"
port = 10018
path = "/"
url = "ws://#{host}:#{port}#{path}"
server = new WebSocketPubSub(host: host, port: port)
server.start()
client1 = undefined
client2 = undefined

describe "WSPubSubClient", ->

  beforeEach ->
    client1.close() if client1?
    
  it "create a client with a url", (done) ->
    client1 = new WSPubSubClient name: "client1a", url: url
    client1.on "open", done
    
  it "create a client with a websocket connection", (done) ->
    ws = new WebSocket url
    console.log JSON.stringify ws
    client1 = new WSPubSubClient name: "client1b", ws: ws
    client1.on "open", done
  
   it "client 1 can subscribe to a channel", (done) ->
    client1 = new WSPubSubClient name: "client1c", url: url
    client1.on "open", ->
      client1.subscribe "test"
      setTimeout done, 500
      
   it "client 2 can publish to the same channel and client 1 will receive the message", (done) ->
    message = "this is a test"
    
    client1 = new WSPubSubClient name: "client1d", url: url
    client1.on "open", ->
      client1.subscribe "test"
      client2 = new WSPubSubClient name: "client2", url: url
      client2.on "open", ->
        client1.on "message", (msg) ->
          console.log "here"
          msg.channel.should.equal "TEST" 
          msg.message.should.equal message 
          done()
          
        client2.publish "test", message