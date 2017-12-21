
'use strict'


###

* **happy**
  * **success**

* **sad**
  * **anomaly**—a sanity check failed that gets logged but does not lead to a crash.

  * **failure**—a well-known, uwanted but *recoverable* outcome, e.g. `image_optim` runs but bails
    out with error code `1` and a `stderr` output that contains 'is not an image or there is no optimizer
    for it'. An error due to user input data, not a software misbehavior.

  * **defect**—software misconfiguration *on a node*;

* **bad**
  * **crash**—software misconfiguration *on the server*;

  * **error**—something else went wrong. Failure to distinguish between a software bug, a vandal
    image or a hardware failure. Application behavior is undefined. Errors should never occur.

###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'HSB'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge

# @x = 42
# @f = => debug 'f', @x
# @g = -> debug 'g', @x
# @f()
# @g()
# { f, g, } = @
# f()
# g()

# process.exit 1

#-----------------------------------------------------------------------------------------------------------
get_location = ( delta = 0 ) ->
  ### TAINT probably a good idea to use a tested library for this ###
  # debug ( new Error() ).stack
  return ( ( ( new Error() ).stack.split '\n' )[ delta + 2 ] ? '(unknown)' ).replace /^.*?\((.*)\).*?$/, '$1'

#-----------------------------------------------------------------------------------------------------------
@happy = ( x ) ->
  ### TAINT what to do with exceptions? ###
  return x                            if @is_happy  x
  return x.value                      if @is_sad    x
  return x.message ? x.code ? 'crash' if @is_crash  x
  return x.message ? x

#-----------------------------------------------------------------------------------------------------------
@_get_cmv = ( P... ) ->
  throw new Error "ecpected 0 to 3 arguments, got #{arity}" unless ( arity = P.length ) <= 3
  [ code, message, value, ] = P
  code    ?= 'defect'
  message ?= null
  # value   ?= if arity is 3 then value else null
  return [ code, message, value, ]

#-----------------------------------------------------------------------------------------------------------
@sad = ( code, message, value ) ->
  [ code, message, value, ] = @_get_cmv.apply @, arguments
  value                     = if @is_sad value then value.value else value
  return { '~isa': 'HSB/sad', code, message, value, }

#-----------------------------------------------------------------------------------------------------------
@new_failure  = ( code, message, value ) -> @sad "failure/#{code}", message, value ? null
@new_defect   = ( code, message, value ) -> @sad "defect/#{code}",  message, value ? null

#-----------------------------------------------------------------------------------------------------------
@is_happy     = ( x ) -> not @is_unhappy x
@is_sad       = ( x ) -> ( CND.type_of x ) is 'HSB/sad'
@is_crash     = ( x ) -> ( CND.type_of x ) is 'HSB/crash'
@is_bad       = ( x ) -> ( CND.isa_jserror x ) or       ( @is_crash x )
@is_error     = ( x ) -> ( CND.isa_jserror x ) and not  ( @is_crash x )
@is_unhappy   = ( x ) -> ( @is_sad x ) or ( CND.isa_jserror x )

#-----------------------------------------------------------------------------------------------------------
@_get_cmad = ( P... ) ->
  switch arity = P.length
    when 0 then [ code, message, advice, delta, ] = [ 'crash', "an unrecoverable condition occurred", null, 1, ]
    when 1 then [ code, message, advice, delta, ] = [ P[ 0 ],  "an unrecoverable condition occurred", null, 1, ]
    when 2 then [ code, message, advice, delta, ] = [ P[ 0 ], P[ 1 ],   null, 1, ]
    when 3 then [ code, message, advice, delta, ] = [ P[ 0 ], P[ 1 ], P[ 2 ], 1, ]
    when 4 then [ code, message, advice, delta, ] = P
    else throw new Error "ecpected 0 to 4 arguments, got #{arity}"
  return { code, message, advice, delta, }

#-----------------------------------------------------------------------------------------------------------
@crash = ( code, message, advice = null ) -> throw @_new_crash code, message, advice, 1

#-----------------------------------------------------------------------------------------------------------
@_new_crash = ( code, message, advice, delta ) ->
  ## when isa_jserror code, just
  { code, message, advice, delta, } = @_get_cmad.apply @, arguments
  if CND.isa_jserror code
    R           = code
    R.message   = message if message?
  else
    R           = new Error message
    R.code      = code
  #.........................................................................................................
  R.message  ?= ''
  R.message   = "CRASH code: #{rpr code}\n#{message}" unless R.message.startsWith 'CRASH code: '
  R.advice    = advice
  R.location  = get_location delta + 1
  R[ '~isa' ] = 'HSB/crash'
  #.........................................................................................................
  return R


#===========================================================================================================
# EXCEPTION HANDLING
#-----------------------------------------------------------------------------------------------------------
exit_codes =
  error:      1
  crash:      2
  notfound:   127

#-----------------------------------------------------------------------------------------------------------
@exit_handler = ( exception ) ->
  # throw exception unless @is_error exception
  debug '55567', rpr exception
  # throw exception unless @is_crash exception
  if @is_crash exception
    print               = warn
    message             = exception.message ? "CRASH code: crash\nan unrecoverable condition occurred"
    [ head, tail..., ]  = message.split '\n'
  else
    print               = alert
    message             = 'ROGUE EXCEPTION: ' + ( exception.message ? "an unrecoverable condition occurred" )
    [ head, tail..., ]  = message.split '\n'
  print CND.reverse ' ' + head + ' '
  warn line for line in tail
  ### TAINT should have a way to set exit code explicitly ###
  whisper exception.stack
  process.exit exit_codes[ exception.code ] ? exit_codes[ 'error' ]

# #-----------------------------------------------------------------------------------------------------------
# @remove_exit_handler = -> process.removeListener 'uncaughtException', @exit_handler

############################################################################################################
do ( ME = @ ) ->
  for name, method of ME
    continue unless CND.isa_function method
    ME[ name ] = method.bind ME

############################################################################################################
# process.on 'uncaughtException', @exit_handler

# @remove_exit_handler()
# @crash 'notfound', "didn't find something"
# @crash 'oops'



