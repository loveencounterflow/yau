
# Y<sub>*et*</sub>A<sub>*nother*</sub>U<sub>*tility*</sub>

YAU provides a few methods and a style guide to write asynchronous, possibly
distributed code under the actor model with asynchronous events, similar to the
[Akka](https://doc.akka.io/docs/akka/current/guide/tutorial_1.html) framework.

<!--
'use strict'

### https://ponyfoo.com/articles/understanding-javascript-async-await ###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'AWAIT-PROMISES2'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
HSB                       = require '/home/flow/io/kleinbild-rack/kbm/lib/happy-sad-bad'
{ happy, sad, is_sad, new_defect, new_failure, is_crash, crash, is_unhappy, is_happy, } = HSB;
{ after, immediately: defer, }                = CND.suspend
{ promisify, }            = require 'util'
jr                        = JSON.stringify

### https://github.com/sindresorhus/emittery ###
Emittery                  = require 'emittery'
 -->

```
# xemitter
###

xemitter uses `sindresorhus/emittery` to provide an event emitter and task delegation facility that
simplifies building asynchronous applications using the Actor pattern.

Events are pairs of channel names and arbitrary data items. Events are emitted by emitter functions.

An arbitrary number of listeners can listen on any given channel. Listeners may be synchronous (returning
anything but a promise) or asynchronous (returning a promise). Each listener produces a value, be it
implicitly (`undefined`) or explicitly (by using `return x` or `resolve x`). The outcomes of all listeners
are collected into an array of values, which may or may not be consumed by emitters.

Delegators are (inherently asynchronous) emitter functions that not only emit events, but that also use
the result(s) that the event listener(s), if any, produced.

Because of the inherent unpredictability of the asynchronous mode of operation, no guarantee is made about
the ordering of values in the event result array. Since an important use case for event emitting is task
delegation, there is a way to distinguish a primary result from spurious and secondary results: On the one
hand, up to one listener may bind to a channel using `XMT.primary_on`. Whatever values(s) that listener
produces when answering an event will be wrapped into a nonce object. The delegator then uses `await
XMT.delegate` or `XMT.select await XMT.emit` to retrieve up to one primary item from the event results:

```
# define a function that delegates some task:
sample_delegator = ->
result = await delegate 'some_task', 42
if is_sad result
  ... sad path ...
else
  ... happy path ...
  return some_value

# use the delegator:
sample_delegator()
.then ( x ) ->
  return error_handler x if is_sad x
  # xxx
  help 'resolved', jr x
.catch error_handler
```


###

#-----------------------------------------------------------------------------------------------------------
@_emitter = new Emittery()
@_has_primary_listeners = {}

#-----------------------------------------------------------------------------------------------------------
@_mark_as_primary = ( x ) -> { '~isa': 'XEMITTER/preferred', value: x, }

#-----------------------------------------------------------------------------------------------------------
@select = ( values ) -> ( values.filter ( x ) -> CND.isa x, 'XEMITTER/preferred' )[ 0 ]?.value ? null

#-----------------------------------------------------------------------------------------------------------
@primary_on = ( channel, listener ) ->
if @_has_primary_listeners[ channel ]
  throw new Error "channel #{rpr channel} already has a primary listener"
@_has_primary_listeners[ channel ] = yes
@_emitter.on channel, ( data ) =>
  return @_mark_as_primary await listener data

#-----------------------------------------------------------------------------------------------------------
@also_on = ( channel, listener ) ->
@_emitter.on channel, listener

#-----------------------------------------------------------------------------------------------------------
@emit     = ( channel, data ) ->               @_emitter.emit channel, data
@delegate = ( channel, data ) -> @select await @_emitter.emit channel, data

# debug '22621', Object::toString.call @delegate

############################################################################################################
for name, value of L = @
### TAINT poor man's 'callable' detection ###
continue unless CND.isa_function value.bind
L[ name ] = value.bind L
```

```
{ select, emit, delegate, also_on, primary_on, } = require 'xemitter'

#-----------------------------------------------------------------------------------------------------------
error_handler = ( reason ) ->
  if is_sad reason
    return urge 'this is sad:', jr reason
  if is_crash reason
    warn CND.reverse 'bad'
    warn 'this is a crash'
    warn jr reason
    process.exit 1
  # don't throw new Error( reason );
  # throw reason
  alert CND.reverse 'evil'
  alert reason
  return null

#-----------------------------------------------------------------------------------------------------------
also_on 'some_task_A', ( data ) ->
  debug 'on some_task_A', jr data
  return 'a secondary result'

#-----------------------------------------------------------------------------------------------------------
also_on 'some_task_B', ( data ) ->
  debug 'on some_task_B', jr data
  return 'a secondary result'
```

```
# use_sample_delegator_A

#-----------------------------------------------------------------------------------------------------------
primary_on 'some_task_A', ( data ) ->
debug 'on some_task_A', jr data
return new Promise ( pass, toss ) ->
  if Math.random() > 0.5
    pass "a happy primary result"
  else
    pass new_failure 'code42', "a sad primary result"
  return null

#-----------------------------------------------------------------------------------------------------------
sample_delegator_A = ->
result = await delegate 'some_task_A', 42
# result = select await emit 'some_task_A', 42
if is_sad result
  urge 'sample_delegator_A sad result:    ', jr result
  return null
else
  help 'sample_delegator_A happy result:  ', jr result
  return "**#{result}**"

#-----------------------------------------------------------------------------------------------------------
sample_delegator_A()
.then ( x ) ->
  return error_handler x if is_sad x
  # xxx
  help 'resolved', jr x
.catch error_handler
```

```
# use_sample_delegator_B

#===========================================================================================================
### Synchronous contractors without promises and asynchronous contractors with promises show the same
behavior; crucially, **the delegator does not have to be aware of any difference between the two**: ###
if settings.use_promises_in_contractor
info "using contractor with promises"
#-----------------------------------------------------------------------------------------------------------
primary_on 'some_task_B', ( data ) ->
  debug 'on some_task_B', jr data
  return new Promise ( resolve, reject ) ->
    [ a, b, ] = data
    return reject new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null if b is 0
    resolve a / b
else
info "using contractor *without* promises"
#-----------------------------------------------------------------------------------------------------------
primary_on 'some_task_B', ( data ) ->
  debug 'on some_task_B', jr data
  [ a, b, ] = data
  throw new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null if b is 0
  return a / b

#-----------------------------------------------------------------------------------------------------------
sample_delegator_B = ->
try
  #.......................................................................................................
  info "computing 4 / 5"
  result_1 = await delegate 'some_task_B', [ 4, 5, ]
  info "computing 4 / 5: #{result_1}"
  #.......................................................................................................
  info "computing 3 / 0"
  result_2 = await delegate 'some_task_B', [ 3, 0, ]
  info "computing 3 / 0: #{result_2}"
  #.......................................................................................................
  # In the case of a style B contractor, only happy results are resolved; sad and bad results are
  # rejected and end up in the catch clause:
  return [ result_1, result_2, ]
catch unhappy
  warn '28921', unhappy
  if is_sad unhappy
    # deal with failures: possibly log where and what occurred, return a replacement value (that may in
    # itself by happy or sad):
    result_2 = happy unhappy
    urge "computing 3 / 0: #{result_2}"
    urge 'sample_delegator_B sad result:    ', jr unhappy
    return null
  # refuse to deal with anything else:
  throw unhappy

#-----------------------------------------------------------------------------------------------------------
sample_delegator_B()
.then ( x ) ->
  return error_handler x if is_sad x
  # xxx
  help 'resolved', jr x
.catch error_handler
```

```
use_sample_delegator_A()
use_sample_delegator_B { use_promises_in_contractor: yes, }
use_sample_delegator_B { use_promises_in_contractor: no, }
```







