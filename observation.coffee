# Observers
# v0.1.0

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
    if _.isString(events[0]) and events.length is 1
      events = events[0].split(" ")

    # If an array of events was passed, we should intuit proper handler
    # names, and verify that they exist at runtime.
    #
    if _.isObject(events[0])
      events = events[0]
    else if _.isString(events[0])
      parsedEvents = {}
      _.each events, (e) =>
        # Determine event handlers based on the event name.
        [action, scope] = e.split(':')
        # `send:task` -> `onSendTask`
        handler = ["on", capitalize(action), capitalize(scope)].join('')
        # If the handler function does not exist, bail out of
        # binding and throw an error.
        handler = @[handler] || throw new InvalidBindingError(e, handler)
        parsedEvents[e] = handler
      events = parsedEvents
    else
      throw new TypeError "Observe accepts either a String, an Array of Strings, or an Object."

    # Target objects must have a CID for use registering events.
    target.cid = _.uniqueId('observed') unless target.cid

    # Create or append to the list of observed objects.
    (@_observedObjects ||= []).push target

    # Conditionally create a hash of events that will be registered
    # by this call to observe.
    targetEvents = (@_observers ||= {})[target.cid] ||= {}

    # Create event listeners for each event and handler specified.
    #
    for own event, handler of events
      target.on event, handler
      (targetEvents[event] ||= []).push handler

    true

  # Public: Stop observing an object and remove all event listeners created
  # through the `#observe` call.
  #
  # object - The Object to stop observing. If null, all observers will be 
  # removed. (Optional)
  #
  # Returns nothing.
  stopObserving: (target) ->
    unless target
      @stopObserving target for target in @_observedObjects
    events = @_observers[target.cid]
    for own event, handlers of events
      for handler, index in handlers
        target.off event, handler
        events[event][index] = null
        delete events[event][index]
        false


    # Remove the target object from the list of observed objects.
    @_observedObjects.pop(target)
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
        false

    true

exports = module?.exports || this
exports.Observers = Observers
