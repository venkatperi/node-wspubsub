require "./property-support"
EventEmitter = require("events").EventEmitter

module.exports = class Queue extends EventEmitter
  
  @property 'length',
    get: -> @queue.length - @offset

  @property 'isEmpty',
    get: -> @queue.length = 0

  constructor: ->
    @queue = []
    @offset = 0

  #Adds an object to the end of the queue 
  enqueue: (item) =>
    @queue.push item
    @emit "enqueue"

  # Removes and returns the object at the beginning of the Queue
  dequeue: =>
    return undefined if @queue.length == 0
    
    # get the item at the front of the queue
    item = @queue[@offset]
    
    # increment the offset and remove the free space if necessary
    if ++@offset * 2 >= @queue.length
      @queue = @queue.slice(@offset)
      @offset = 0
      
    @emit "dequeue"
      
    # return the dequeued item
    item

  ### Returns the item at the front of the queue (without dequeuing it). If the
  # queue is empty then undefined is returned.
  ###
  peek: =>
    if @queue.length > 0 then @queue[@offset] else undefined

  # Remove all objects from the queue
  clear: =>
    @queue = []
    @offset = 0
    