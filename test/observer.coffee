_              = require 'underscore'
{EventEmitter} = require 'events'
{Observers}     = require '../observer'

class TestEmitter extends EventEmitter
  constructor: ->
    @
  start: ->
    @emit 'test:start'
  raise: ->
    @emit 'test:raise'
  end: ->
    @emit 'test:end'
  
class TestClient
  constructor: (@emitter, done) ->
    @events = []
    @
  observeByString: ->
    @observe @emitter, 'test:start test:raise test:end'
  
  observeByArray: ->
    @observe @emitter, ['test:start', 'test:raise', 'test:end']
  
  observeByArguments: ->
    @observe @emitter, 'test:start', 'test:raise', 'test:end'
    
  observeByHash: ->
    @observe @emitter,
      'test:start': @handleStart
      'test:raise': @handleRaise
      'test:end':   @handleEnd

  multipleObserve: ->
    @observeByString()
    @observe @emitter, 
      'test:raise': @handleRaise
    
  faultyObserve: ->
    @observe @emitter, 'test:fail'
    
  onTestStart: =>
    @events.push 'test:start'
    
  onTestRaise: =>
    console.log "onTestRaise was erroneously called."
    @events.push 'test:raise'
    
  onTestEnd: =>
    @events.push 'test:end'
    @stopObserving()
    
  handleStart: =>
    @events.push 'test:start'
    
  handleRaise: =>
    console.log "handleRaise was erroneously called."
    @events.push 'test:raise'
    
  handleEnd: =>
    @events.push 'test:end'
    @stopObserving()
    
_.extend TestClient::, Observers

testStartEnd = (emitter, client, done) ->
  emitter.start()
  emitter.end()
  emitter.raise()
  if client.events.length is 2 
    done()
  else
    done("Unexpected number of events.")
    
describe 'Observer', ->
  emitter = new TestEmitter()
  client = new TestClient(emitter)
    
  beforeEach ->
    emitter = new TestEmitter()
    client = new TestClient(emitter)
  
  describe '#observe', ->
    it 'should be able to observe objects by a string', (done) ->      
      client.observeByString()
      testStartEnd emitter, client, done
    
    it 'should be able to observe objects by an array', (done) ->
      client.observeByArray()
      testStartEnd emitter, client, done

    it 'should be able to observe objects by trailing arguments', (done) ->
      client.observeByArguments()
      testStartEnd emitter, client, done
    
    it 'should be able to observe objects by hash', (done) ->
      client.observeByHash()
      testStartEnd emitter, client, done
    
    it 'should not fire events after #stopObserving is called', (done) ->
      client.observeByString()
      testStartEnd emitter, client, done
      
    it 'should file events from multiple #observe calls', (done) ->
      client.multipleObserve()
      testStartEnd emitter, client, done
    
    it 'should raise an exception when an intuited function is bound', (done) ->
      try 
        client.faultyObserve()
      catch error
        if error.name is 'InvalidBindingError'
          done()
        else
          done(error)
      
      
      
      