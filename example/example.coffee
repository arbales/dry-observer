# Some namespace you have for your base view.
App = {}

# Your Base view could automatically support. 
class App.View extends Backbone.View
  # Your Backbone.View subclass might call `#stopObserving` when
  # its removed to destory references between your view and the 
  # other objects its observing.
  remove: ->
    @stopObserving()
    super()

_.extend App.View::, Observers

# A sample Model that emits events, imagine its your
# super slick Push service manager.
class Transport extends Backbone.Model
 start: ->
   setTimeout =>
     @trigger 'transport:up'
   , 2000
   setTimeout =>
     @trigger 'transport:down'
   , 6000
   setTimeout =>
     @trigger 'message:receive'
   , 10000
   @

# A view that displays the status of your slick push service.
# For the sake of the example, it removes itself when the
# push service is down.
class StatusView extends App.View
  initialize: ->
    super
    this.observe @model, 'transport:up transport:down message:receive'
  
  onTransportUp: =>
    $(@el).text 'Transport Online'

  onTransportDown: =>
    $(@el).text 'Transport Offline'
    alert 'Transport is Offline, view will be removed.'
    @remove()

  # Because `#remove` automatically stops observing changes on the
  # model, this should never get called.
  onMessageReceive: =>
    alert 'This should never run.'

this.Transport = Transport
this.StatusView = StatusView
