
# Velocity v1.0.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

```coffee
velocity = Velocity()

# Add a {time, position} pair for computing the velocity.
velocity.update Date.now(), 0

# Compute the current velocity using the pairs passed to `update`.
velocity.get()

# The slope direction is computed for every `update` call. Can equal 1, 0, or -1.
velocity.direction

# Maximum amount of time before a {time, position} pair is pruned. Defaults to 1000 ms.
velocity.maxAge

# Reset the `Velocity` instance to its initial state.
velocity.reset()
```

### Qwerks

- The return value of `get` is not cached.
- The velocity is computed using the first and last events.
- The `direction` equals zero until `update` is called at least twice.
- The velocity resets to zero whenever the direction changes.

