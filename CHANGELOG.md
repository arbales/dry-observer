# Initial Release (Oct. 22. 2012)

## 0.2.0
* You can now pass a space-separated list of events inside a hash paired
  with a single event handler. This matches Backbone's `#on` method, and
  allows you to bind multiple thigns to `#render` for example.

* The internal mechanism for adding and removing event listeners was
  changed in implementing the above. Users of older versions of Backbone
  will no longer have their objects monkey-patched.

* When intuiting event handler names, **dry-observer** will now guess
  the standalone event name after the prefixed name, allowing you to use
  plain event names and handlers:

  `this.observe(model, 'search')` will now attempt `#onSearch` followed
  by `#search`

* Backbone 0.9.0+ compatible objects will now receive the "context"
  parameter during binding.
