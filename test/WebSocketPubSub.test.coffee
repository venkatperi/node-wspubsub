should = require( "should" )
assert = require( "assert" )
WebSocketPubSub = require '../lib/WebSocketPubSub'
WebSocket = require "ws"

server = {}
client1 = {}
client2 = {}
host = "localhost"
port = 10018
path = "/"
url = "ws://#{host}:#{port}#{path}"

describe "WebSocketPubSub", ->
  it "start the server", ->
    server = new WebSocketPubSub(host: host, port: port)
    server.start()

  it "client 1 can subscribe to a channel", (done) ->
    client1 = new WebSocket url
    client1.on "open", ->
      data = command: "subscribe", channels: ["test"] 
      client1.send JSON.stringify(data)
      done()
      
  it "client 2 can publish to the same channel and client 1 will receive the message", (done) ->
    message = "this is a test"
    
    client2 = new WebSocket url
    client2.on "open", ->
      client1.on "message", (msg) ->
        msg.should.equal message 
        done()
        
      data = command: "publish", channel: "test", message: message 
      client2.send JSON.stringify(data)
      
  it "stop the server", ->
    server.stop()