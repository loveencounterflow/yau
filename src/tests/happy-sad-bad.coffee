

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'KBM/TESTS/HAPPY-SAD-BAD'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# PATH                      = require 'path'
# FS                        = require 'fs'
# OS                        = require 'os'
TAP                       = require 'tap'
#...........................................................................................................
# L                         = ( P... ) -> debug CND.rainbow P...
{ defer
  every
  jr
  jrnl
  assign
  copy_without
  pluck
  new_switcher  }         = require '../utilities'
eq                        = CND.equals
#...........................................................................................................
HSB                       = require '../happy-sad-bad'

#-----------------------------------------------------------------------------------------------------------
TAP.test "basics", ( T ) ->
  probes_and_matchers = [
    [ [], {"~isa":"error/sad","code":"defect","message":null,"value":undefined}]
    [ [ null, null, 42 ], {"~isa":"error/sad","code":"defect","message":null,"value":42}]
    [ [ null, null, undefined ], {"~isa":"error/sad","code":"defect","message":null,"value":undefined}]
    [ [ null, null, null ], {"~isa":"error/sad","code":"defect","message":null,"value":null}]
    [ [ 'anomaly', null, 42 ], {"~isa":"error/sad","code":"anomaly","message":null,"value":42}]
    [ [ 'anomaly', "this wasn't expected", 42], {"~isa":"error/sad","code":"anomaly","message":"this wasn't expected","value":42}]
    ]
  { happy, sad, is_sad, new_crash, is_crash, is_unhappy, is_happy, } = HSB
  for [ probe, matcher, ] in probes_and_matchers
    result = sad probe...
    urge ( jr [ probe, result, ] ), ( CND.truth eq result, matcher )
    T.ok eq result, matcher
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "demo", ( T ) ->
  #.........................................................................................................
  index_of = ( x, probe ) ->
    R = x.indexOf probe
    if R < 0
      R = sad 'notfound', "value #{rpr probe} was not found", R
    return R
  #.........................................................................................................
  { happy, sad, is_sad, new_crash, is_crash, is_unhappy, is_happy, } = HSB
  T.ok ( index_of 'abcd', 'c' ), 2
  T.ok eq ( is_sad index_of 'abcd', 'x' ), true
  warn 'x'
  if is_sad index = index_of 'abcd', 'x'
    warn index.message
    T.ok eq index, { '~isa': 'error/sad', code: 'notfound', message: 'value \'x\' was not found', value: -1 }
    T.ok eq index.message, "value 'x' was not found"
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "exceptions 1", ( T ) ->
  { happy, sad, is_sad, new_crash, is_crash, crash, is_unhappy, is_happy, } = HSB
  probes_and_matchers = [
    [ -> new_crash()]
    [ -> new_crash 'notfound']
    [ -> new_crash 'notfound', "no such file: path/to/file"]
    ]
  #.........................................................................................................
  for [ probe, matcher, ] in probes_and_matchers
    try probe()
    catch error
      warn error.message
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "exceptions 2", ( T ) ->
  { happy, sad, is_sad, new_crash, is_crash, crash, is_unhappy, is_happy, } = HSB
  probes_and_matchers = [
    [ ( -> crash()                                        ), "CRASH code: 'crash'\nan unrecoverable condition occurred" ]
    [ ( -> crash 'notfound'                               ), "CRASH code: 'notfound'\nan unrecoverable condition occurred" ]
    [ ( -> crash 'notfound', "no such file: path/to/file" ), "CRASH code: 'notfound'\nno such file: path/to/file" ]
    ]
  #.........................................................................................................
  count = 0
  for [ probe, matcher, ] in probes_and_matchers
    try probe()
    catch error
      urge jr error.message
      T.ok eq error.message, matcher
      count += +1
  unless count is probes_and_matchers.length
    T.fail "expected to see #{probes_and_matchers.length} exceptions, only saw #{count}"
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
f = -> TAP.test "basics", ( T ) ->

  try throw new_crash "something went wrong"
  catch error then warn JSON.stringify error
  try throw new_crash 'cx742', "something went wrong"
  catch error then warn JSON.stringify error

  urge()
  urge CND.truth is_happy     "oops"
  urge CND.truth is_happy     new_crash "oops"
  urge CND.truth is_happy     sad "oops"

  urge()
  urge CND.truth is_unhappy   "oops"
  urge CND.truth is_unhappy   new_crash "oops"
  urge CND.truth is_unhappy   sad "oops"

  urge()
  urge CND.truth is_crash  "oops"
  urge CND.truth is_crash  new_crash "oops"
  urge CND.truth is_crash  sad "oops"

  warn happy new Error    "something went wrong, but can deal with it"
  warn happy new_crash "something went wrong, but can deal with it"
  warn happy new_crash 'code-blue', "something went wrong, but can deal with it"
  warn happy 42

  help @new_defect  "not as expected"
  help @new_anomaly "this is strange"


  T.end()
  return null


