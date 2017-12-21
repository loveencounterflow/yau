
'use strict'

### https://ponyfoo.com/articles/understanding-javascript-async-await ###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'YAU/DEMO-2'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
{ happy
  sad
  is_sad
  new_defect
  new_failure
  is_crash
  crash
  is_unhappy
  is_happy              } = require './happy-sad-bad'
{ after, immediately: defer }    = CND.suspend
{ promisify, }            = require 'util'
jr                        = JSON.stringify
#...........................................................................................................
{ select
  emit
  delegate
  on_any
  also_on
  primary_on }            = require './xemitter'

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
on_any ( channel, data ) ->
  whisper "channel: #{rpr channel}, data: #{jr data}"
  return 12345


#===========================================================================================================
# CONTRACTORS
#-----------------------------------------------------------------------------------------------------------
primary_on 'sync_task_that_throws_on_failure', ( data ) ->
  debug 'sync_task_that_throws_on_failure', jr data
  [ a, b, ] = data
  if b is 0
    throw new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null
  return a / b

#-----------------------------------------------------------------------------------------------------------
primary_on 'sync_task_that_returns_on_failure', ( data ) ->
  debug 'sync_task_that_returns_on_failure', jr data
  [ a, b, ] = data
  if b is 0
    return new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null
  return a / b

#-----------------------------------------------------------------------------------------------------------
primary_on 'async_task_that_rejects_on_failure', ( data ) ->
  debug 'async_task_that_rejects_on_failure', jr data
  return new Promise ( resolve, reject ) ->
    [ a, b, ] = data
    if b is 0
      reject new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null
    else
      resolve a / b
    return null

#-----------------------------------------------------------------------------------------------------------
primary_on 'async_task_that_resolves_on_failure', ( data ) ->
  debug 'async_task_that_resolves_on_failure', jr data
  return new Promise ( resolve, reject ) ->
    [ a, b, ] = data
    if b is 0
      resolve new_failure 'divbyzero', "division by zero: #{rpr a} / #{rpr b}", null
    else
      resolve a / b
    return null

#-----------------------------------------------------------------------------------------------------------
sample_delegator = ->
  try
    #.......................................................................................................
    info "computing 4 / 5"
    help 'sync_task_that_throws_on_failure',    await delegate 'sync_task_that_throws_on_failure',     [ 4, 5, ]
    help 'sync_task_that_returns_on_failure',   await delegate 'sync_task_that_returns_on_failure',    [ 4, 5, ]
    help 'async_task_that_rejects_on_failure',  await delegate 'async_task_that_rejects_on_failure',   [ 4, 5, ]
    help 'async_task_that_resolves_on_failure', await delegate 'async_task_that_resolves_on_failure',  [ 4, 5, ]
    #.......................................................................................................
    info "computing 3 / 0"
    # help 'sync_task_that_throws_on_failure',    await delegate 'sync_task_that_throws_on_failure',     [ 3, 0, ]
    # help 'sync_task_that_returns_on_failure',   await delegate 'sync_task_that_returns_on_failure',    [ 3, 0, ]
    # help 'async_task_that_rejects_on_failure',  await delegate 'async_task_that_rejects_on_failure',   [ 3, 0, ]
    help 'async_task_that_resolves_on_failure', await delegate 'async_task_that_resolves_on_failure',  [ 3, 0, ]
    # #.......................................................................................................
    # # In the case of a style B contractor, only happy results are resolved; sad and bad results are
    # # rejected and end up in the catch clause:
    return true
  catch unhappy
    warn '28921', unhappy
    if is_sad unhappy
      # deal with failures: possibly log where and what occurred, return a replacement value (that may in
      # itself by happy or sad):
      result_2 = happy unhappy
      urge "computing 3 / 0: #{result_2}"
      urge 'sample_delegator sad result:    ', jr unhappy
      return null
    # refuse to deal with anything else:
    throw unhappy

#-----------------------------------------------------------------------------------------------------------
sample_delegator()
  .then ( x ) ->
    return error_handler x if is_sad x
    # xxx
    help 'resolved', jr x
  .catch error_handler









