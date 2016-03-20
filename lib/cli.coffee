conf = require "./conf"
parser = require( 'nomnom' )
WebSocketPubSub = require "./WebSocketPubSub"

startServer =  (opts) ->
  server = new WebSocketPubSub opts
  server.start()

parser.script "wspubsub"
parser.command "start"
.option "host",
  help : "Websocket server host"

.option "port",
  help : "Websocket server port"

.option "path",
  help : "Websocket server path"

.help "Start websocket pubsub server"
.callback startServer

parser.parse()

