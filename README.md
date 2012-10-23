## dry-observer
Dryly bind and unbind event listeners and encourage consistent,
pattern-based naming of handlers/callbacks.

[![Build Status](https://secure.travis-ci.org/arbales/dry-observer.png)](http://travis-ci.org/arbales/dry-observer)

```coffeescript
# Observe a Model by passing a hash…
@observe model,
  'song:change'   : @onSongChange
  'volume:change' : @onVolumeChange
  'focus'         : @onFocus

# …or a String or Array.
# Observation will camelCase and prefix your events.
@observe model, 'song:change volume:change focus'

# Stop observing and dereference your model…
@stopObserving model

# …or stop observing /everything/
@stopObserving()

# …or remove a specific handler and cleanup.
@removeObserver model, 'song:change', @onSongChange
```

### Problem
If you're working a lot with Backbone (or other EventEmitter-based
APIs), you may have written or reviewed code that's similar to this:

```coffeescript
# app/assets/javascripts/views/tasks/detail.js.coffee
class TaskDetail extends Backbone.View
  initialize: ->
    @model.on 'change:closed',    @handleUpdatable
    @model.on 'focus',            @handleFocus
    @model.on 'resetAssignee',    @resetAssignee
    @model.on 'positionUpdated',  @updatePosition
    # etc

  remove: ->
    @model.off 'change:closed',   @handleUpdatable
    @model.off 'resetAssignee',   @resetAssignee
    @model.off 'positionUpdated', @updatePosition
    super
```

There a number of problems with this code:

* Events aren't named or formatted uniformly.
* Handlers aren't consistently named, and may or may not rely on arguments passed
  by `#trigger` or `#emit`.
* Repetitive calls to `#on` and `#off` on different objects adds unDRY
  cruft to your codebase and…
* It's easy to forget to bind or unbind events, or update the names of
  your handlers as you go.

### Solution

Observation helps you solve each of these problems by allowing you to
centralize both binding and unbinding to events, and by encouraging
consistent handler naming.

```coffeescript
# app/assets/javascripts/views/tasks/detail.js.coffee
#
class TaskDetail extends App.View
  initialize: ->
    # `#observe` automatically calls `#on` for you, optionally intuiting
    # proper handler names and checking to ensure they exist.
    #
    @observe @model, 'change:closed focus position:updated assignee:reset'
```

To fully leverage the usefullness of Observation, create a base subclass
of Backbone.View you can use to ensure that event listeners
*always* get cleaned up upon view removal.

```coffeescript
# app/assets/javascripts/views/base.js.coffee
#
class App.View extends Backbone.View
  # …
  remove: ->
    # Removes all listeners and references to objects observed by a
    # call to `#observe`
    @stopObserving()
    super

# Add Observers to our View base class.
_.extend App.View::, Observers

# app/assets/javascripts/controllers/task_controller.js.coffee
#
# Elsewhere in your code, you decide to remove your TaskDetail view,
# calling the standard Backbone.View#remove() method, perhaps along
# with navigating elsewhere in your app.

detailView.remove()
```

### Contributions

Patches and bug reports are welcome. Just send a [pull request][pullrequests] or
file an [issue][issues]. [Project Changelog][changelog].

[License][license]

[pullrequests]:         https://github.com/arbales/observation.coffee/pulls
[issues]:               https://github.com/arbales/observation.coffee/issues
[changelog]:            https://github.com/arbales/observation.coffee/blob/master/CHANGELOG.md
[license]:              https://github.com/arbales/observation.coffee/blob/master/LICENSE
