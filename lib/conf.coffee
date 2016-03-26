Conf = require 'node-conf'

opts =
  name : "wspubsub"
  dirs :
    "factory" : "#{__dirname}/.."

conf = Conf( opts )

module.exports = conf


