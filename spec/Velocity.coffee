
Velocity = require ".."

clock = jasmine.clock()
startTime = Date.now()
frames = 0

beforeAll ->
  clock.install()

beforeEach ->
  frames = 0
  clock.mockDate new Date startTime

afterAll ->
  clock.uninstall()

# Convert a `velocity` value back to its `distance`.
computeDistance = (velocity) ->
  velocity / 1000 * (Date.now() - startTime)

Velocity::getLastEvent = ->
  events = @_events
  events[events.length - 1]

# Tick the fake clock for 16 millis.
# The `update` method is passed the current time (first)
# and the last position plus the distance (second).
Velocity::move = (distance) ->

  if @_lastPosition is null
    throw Error "Must first call 'update' once!"

  clock.tick 16
  time = Date.now()
  position = @_lastPosition + distance
  @update time, position

describe "Velocity::update", ->

  it "adds another {time, position} pair for computing the velocity", ->

    v = Velocity()
    v.update startTime, 0

    expect v.get()
      .toBe 0

    expect v.getLastEvent()
      .toEqual {time: Date.now(), position: 0}

    v.move 20

    expect v.getLastEvent()
      .toEqual {time: Date.now(), position: 20}

    expect computeDistance v.get()
      .toBe 20

    v.move 40

    expect v.getLastEvent()
      .toEqual {time: Date.now(), position: 60}

    expect computeDistance v.get()
      .toBe 60

  it "computes `direction` when 2 or more events exist", ->

    v = Velocity()
    v.update startTime, 0

    # The direction is not computed until 2 events are added.
    expect v.direction
      .toBe 0

    # The last position is cached on every call.
    expect v._lastPosition
      .toBe 0

    v.move 10

    expect v.direction
      .toBe 1

    expect v._lastPosition
      .toBe 10

    v.move 10
    expect v.direction
      .toBe 1

    v.move -10
    expect v.direction
      .toBe -1

    # Remove all but two events when direction changes.
    expect v._events.length
      .toBe 2

  it "prunes events older than `maxAge` before updating", ->

    v = Velocity()
    v.update startTime, 0

    spy = spyOn v, "_prune"

    clock.tick v.maxAge + 1
    v.update Date.now(), 10

    expect spy.calls.allArgs()
      .toEqual [ [v.maxAge] ]

describe "Velocity::get", ->

  it "returns zero when less than two events exist", ->

    v = Velocity()
    expect v.get()
      .toBe 0

    v.update startTime, 0
    expect v.get()
      .toBe 0

  it "computes velocity using the first and last events", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10
    v.move 10

    expect computeDistance v.get()
      .toBe 20

  it "prunes events older than `maxAge` before computing the velocity", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10

    clock.tick v.maxAge + 1
    v.move 10
    v.move 10

    spy = spyOn v, "_prune"
    v.get()

    expect spy.calls.allArgs()
      .toEqual [ [v.maxAge] ]

describe "Velocity::reset", ->

  it "resets the instance to its starting values", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10
    v.reset()

    expect v._events
      .toEqual []

    expect v._direction
      .toBe 0

    expect v._lastPosition
      .toBe null

describe "Velocity::_prune", ->

  it "removes events older than a number of milliseconds", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10
    clock.tick 200
    v.move 10

    expected = v._events.slice -1
    v._prune 100

    expect v._events
      .toEqual expected

  it "removes zero events if none are old enough", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10
    v.move 10
    v._prune 100

    expect v._events.length
      .toBe 3

  it "removes all events if all are old enough", ->

    v = Velocity()
    v.update startTime, 0
    v.move 10
    v.move 10

    clock.tick 200
    v._prune 100

    expect v._events.length
      .toBe 0

    # The `_lastPosition` is preserved to help compute direction.
    expect v._lastPosition
      .not.toBe null

  it "keeps events that are just 1 millisecond from being too old", ->

    v = Velocity()
    v.update startTime, 0
    clock.tick 100
    v.update Date.now(), 20

    expected = v._events.slice()
    v._prune 100

    expect v._events
      .toEqual expected
