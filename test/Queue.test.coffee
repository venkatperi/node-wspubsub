should = require( "should" )
assert = require( "assert" )
Queue = require '../lib/Queue'

obj1 = name: "object 1"
obj2 = name: "object 2"
obj3 = name: "object 3"
obj4 = name: "object 4"
queue = {}

describe "Queue", ->

  beforeEach ->
    queue = new Queue()

  describe "length", ->
    it "is empty to begin", ->
      queue.length.should.equal 0
      
    it "enqueue increases the length", ->
      queue.enqueue obj1 
      queue.enqueue obj2 
      queue.enqueue obj3 
      queue.enqueue obj4 
      queue.length.should.equal 4

    it "dequeue decreases the length", ->
      queue.dequeue()
      queue.dequeue()
      queue.length.should.equal 2

    it "clear the queue", ->
      queue.clear()
      queue.length.should.equal 0

  describe "enqueue/dequeue/peek", ->
  
    it "dequeue returns undefined when the queue is empty", ->
      queue.dequeue().should.be.undefined
              
    it "peek returns undefined when the queue is empty", ->
      queue.peek().should.be.undefined

    it "queue order is FIFO", ->
      queue.enqueue obj1 
      queue.enqueue obj2 
      queue.enqueue obj3 
      queue.enqueue obj4 

      queue.dequeue().should.equal obj1
      queue.dequeue().should.equal obj2
      queue.dequeue().should.equal obj3
      queue.dequeue().should.equal obj4

    it "peek returns from the fron of the queue (first in) but leaves the queue unchanged", ->
      queue.clear()
      queue.enqueue obj1 
      queue.enqueue obj2 
      queue.enqueue obj3 
      queue.enqueue obj4 

      l1 = queue.length
      queue.peek().should.equal obj1
      queue.length.should.equal l1