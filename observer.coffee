###
dry-observer
v0.2.2

LICENSE: http://github.com/arbales/dry-observer/raw/master/LICENSE
###

root = this
_ = root._

if (!_ && require?)
  _ = require('underscore')

# InvalidBindingError is thrown when an object does not
# implement a handler method.
#
class InvalidBindingError extends Error
  constructor: (event, handler) ->
    @name = "InvalidBindingError"
    @message = "Unable create binding for `#{event}` due unimplemented handler: `##{handler}`"

# Internal: Capitalizes a string or returns an empty string if 
# one wasn't provided.
#
# Returns a String.
capitalize = (string) ->
  return "" unless string
  string.charAt(0).toUpperCase() + string.slice(1)

deprecatedBackbone = Backbone? && parseFloat(Backbone.VERSION) < 0.9

eventSplitter = /\s+/

createListener = (target, events, callback, context) ->
  # EventEmitter
  if target.addListener
    for event in events.split(eventSplitter)
      target.addListener(event, callback)

  # Backbone < 0.9.0
  else if deprecatedBackbone
    for event in events.split(eventSplitter)
      target.bind(event, callback, context)

  # Backbone >= 0.9.0, Backbone-compatible objects
  else if target.on
    target.on(events, callback, context)
  else
    throw new TypeError "Expected an EventEmitter or Backbone.Events-compatible target."


# Internal: Use the Backbone 0.9.0 interface for unbinding
# events for EventEmitter and all versions of Backbone.
#
destroyListener = (target, events, callback) ->
  # EventEmitter
  if target.removeListener
    for event in events.split(eventSplitter)
      target.removeListener(event, callback)

  # Backbone < 0.9.0
  else if deprecatedBackbone
    for event in events.split(eventSplitter)
      target.unbind(event, callback)

  # Backbone >= 0.9.0, Backbone-compatible objects
  else if target.off
    target.off(events, callback)
  else
    throw new TypeError "Expected an EventEmitter or Backbone.Events-compatible target."

Observers =
  # Internal: An array of objects for which `#observe`
  # was called on. Used for automatic cleanup via `#stopObserving`.
  _observedObjects: null

  # Internal: A plain object contianing the events and handlers
  # for each observedObject.
  #
  # Example:
  #
  #     @_observers =
  #       'c123':
  #         'change:assignee': [Function, Function]
  #         'focus':           [Function]
  #
  _observers: null

  # Public: Bind events on a given object to handlers.
  #
  # object - The Object to stop observing. Must conform to the EventEmitter API.
  # events - A plain Object with events and handlers and key/value pairs OR
  #          An Array or space-separated String of event names for which
  #          handlers will be attached based on standard naming convention.
  #
  # Examples
  #
  #   @observe model, 
  #     "focus"         : @onFocus
  #     "send:task"     : @onSendTask
  #     "add:comment"   : @onAddComment
  #
  #   @observe model, ['focus', 'send:task', 'add:comment']
  #
  #   @observe model, 'focus send:task add:comment'
  #
  # Returns nothing.
  # Raises InvalidBindingError if an implicit handler function could not be found.
  observe: (target, events...) ->

    context = null

    @_eventHandlerPrefix ||= 'on'

    if events.length is 1
      if (_ events[0]).isString()
        events = events[0].split(" ")

      if (_ events[0]).isObject()
        events = events[0]

    # if the last element is an object, its the context
    else if _.isObject(_.last(events))
      context = events.pop()

    # If only strings were passed, intuit proper handler
    # names, and verify that they exist at runtime.
    #
    if _.isString(events[0])
      parsedEvents = {}
      _.each events, (e) =>
        # Determine event handlers based on the event name.
        [action, scope] = e.split(':')
        # `send:task` -> `onSendTask`
        handler = [@_eventHandlerPrefix, capitalize(action), capitalize(scope)].join('')
        # If the handler function does not exist, bail out of
        # binding and throw an error.
        handler = @[handler] || @[e] || throw new InvalidBindingError(e, handler)
        parsedEvents[e] = handler
      events = parsedEvents

    unless _.isObject(events)
      throw new TypeError "Observe accepts either a String, an Array of Strings, or an Object."

    # Target objects must have a CID for use registering events.
    target.cid = _.uniqueId('observed') unless target.cid

    # Create or append to the list of observed objects.
    @_observedObjects = _.union (@_observedObjects ||= []), target

    # Conditionally create a hash of events that will be registered
    # by this call to observe.
    targetEvents = (@_observers ||= {})[target.cid] ||= {}

    # Create event listeners for each event and handler specified.
    #
    for own event, handler of events
      createListener target, event, handler, context
      (targetEvents[event] ||= []).push handler

    true

  # Public: Stop observing an object and remove all event listeners created
  # through the `#observe` call.
  #
  # object - The Object to stop observing. If null, all observers will be 
  # removed. (Optional)
  #
  # Returns nothing.
  stopObserving: (target = false) ->
    return false unless @_observedObjects && @_observers
    unless target
      for target in @_observedObjects
        @stopObserving target if target
      return false
    events = @_observers[target.cid]
    for own event, handlers of events
      for handler, index in handlers
        destroyListener target, event, handler
        delete [handlers][index]

    # Remove the target object from the list of observed objects.
    delete @_observedObjects[_.indexOf(@_observedObjects, target)]
    delete @_observers[target.cid]

    true

  # Public: Remove an observer by event name.
  #
  # object - The object to stop observing.
  # event - The name of the event.
  #
  # Returns nothing.
  removeObserver: (target, event, handlerToRemove) ->
    unless target
       @removeObserver target for target in @_observedObjects
    events = _observers[target.cid]
    for own event, handlers of events
      for handler, index in handlers
        # If we've specified a handler to remove, only remove it.
        continue if handlerToRemove and handler isnt handlerToRemove
        target.off event, handler
        events[event][index] = null
        delete events[event][index]

    true

exports = module?.exports || this
exports.Observers = Observers
