
Type = require "Type"

type = Type "Velocity"

type.defineArgs
  maxAge: Number

type.defineValues (options) ->

  maxAge: options.maxAge or 1000

  _events: []

  _direction: 0

  _lastPosition: null

type.defineGetters

  direction: -> @_direction

type.defineMethods

  get: ->

    @_prune @maxAge
    eventCount = @_events.length
    return 0 if eventCount < 2

    first = @_events[0]
    last = @_events[eventCount - 1]

    distance = last.position - first.position
    elapsedTime = last.time - first.time
    return distance / elapsedTime * 1000

  update: (time, position) ->

    @_prune @maxAge
    @_events.push {time, position}

    if @_lastPosition isnt null
      return @_computeDirection position

    @_lastPosition = position
    return

  reset: ->
    if @_events.length
      @_events.length = 0
      @_direction = 0
      @_lastPosition = null
    return

  _prune: (ms) ->
    startTime = Date.now() - ms

    events = @_events
    eventCount = events.length
    return if eventCount is 0

    index = 0
    while event = events[index]
      break if event.time >= startTime
      index += 1

    # Avoid resetting `_lastPosition` to help compute direction.
    if index is eventCount
      events.length = 0
      @_direction = 0
      return

    if index > 0
      @_events = events.slice index
    return

  # Updates `_direction` and `_lastPosition` using the newest position.
  _computeDirection: (position) ->

    lastDirection = @_direction
    @_direction = if position > @_lastPosition then 1 else -1

    @_lastPosition = position
    return if lastDirection is 0

    # Remove all but the last two events if the direction changed.
    # The direction would equal zero if we only kept one event.
    # That is undesired since we know the true direction.
    if @_direction isnt lastDirection
      @_events = @_events.slice -2
    return

module.exports = type.build()
