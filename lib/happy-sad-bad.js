// Generated by CoffeeScript 2.0.3
(function() {
  'use strict';
  var CND, alert, badge, debug, exit_codes, get_location, help, info, rpr, urge, warn, whisper;

  /*

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

   */
  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'HSB';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  // @x = 42
  // @f = => debug 'f', @x
  // @g = -> debug 'g', @x
  // @f()
  // @g()
  // { f, g, } = @
  // f()
  // g()

  // process.exit 1

  //-----------------------------------------------------------------------------------------------------------
  get_location = function(delta = 0) {
    var ref;
    /* TAINT probably a good idea to use a tested library for this */
    // debug ( new Error() ).stack
    return ((ref = ((new Error()).stack.split('\n'))[delta + 2]) != null ? ref : '(unknown)').replace(/^.*?\((.*)\).*?$/, '$1');
  };

  //-----------------------------------------------------------------------------------------------------------
  this.happy = function(x) {
    var ref, ref1, ref2;
    if (this.is_happy(x)) {
      /* TAINT what to do with exceptions? */
      return x;
    }
    if (this.is_sad(x)) {
      return x.value;
    }
    if (this.is_crash(x)) {
      return (ref = (ref1 = x.message) != null ? ref1 : x.code) != null ? ref : 'crash';
    }
    return (ref2 = x.message) != null ? ref2 : x;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._get_cmv = function(...P) {
    var arity, code, message, value;
    if (!((arity = P.length) <= 3)) {
      throw new Error(`ecpected 0 to 3 arguments, got ${arity}`);
    }
    [code, message, value] = P;
    if (code == null) {
      code = 'defect';
    }
    if (message == null) {
      message = null;
    }
    // value   ?= if arity is 3 then value else null
    return [code, message, value];
  };

  //-----------------------------------------------------------------------------------------------------------
  this.sad = function(code, message, value) {
    [code, message, value] = this._get_cmv.apply(this, arguments);
    value = this.is_sad(value) ? value.value : value;
    return {
      '~isa': 'HSB/sad',
      code,
      message,
      value
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_failure = function(code, message, value) {
    return this.sad(`failure/${code}`, message, value != null ? value : null);
  };

  this.new_defect = function(code, message, value) {
    return this.sad(`defect/${code}`, message, value != null ? value : null);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.is_happy = function(x) {
    return !this.is_unhappy(x);
  };

  this.is_sad = function(x) {
    return (CND.type_of(x)) === 'HSB/sad';
  };

  this.is_crash = function(x) {
    return (CND.type_of(x)) === 'HSB/crash';
  };

  this.is_bad = function(x) {
    return (CND.isa_jserror(x)) || (this.is_crash(x));
  };

  this.is_error = function(x) {
    return (CND.isa_jserror(x)) && !(this.is_crash(x));
  };

  this.is_unhappy = function(x) {
    return (this.is_sad(x)) || (CND.isa_jserror(x));
  };

  //-----------------------------------------------------------------------------------------------------------
  this._get_cmad = function(...P) {
    var advice, arity, code, delta, message;
    switch (arity = P.length) {
      case 0:
        [code, message, advice, delta] = ['crash', "an unrecoverable condition occurred", null, 1];
        break;
      case 1:
        [code, message, advice, delta] = [P[0], "an unrecoverable condition occurred", null, 1];
        break;
      case 2:
        [code, message, advice, delta] = [P[0], P[1], null, 1];
        break;
      case 3:
        [code, message, advice, delta] = [P[0], P[1], P[2], 1];
        break;
      case 4:
        [code, message, advice, delta] = P;
        break;
      default:
        throw new Error(`ecpected 0 to 4 arguments, got ${arity}`);
    }
    return {code, message, advice, delta};
  };

  //-----------------------------------------------------------------------------------------------------------
  this.crash = function(code, message, advice = null) {
    throw this._new_crash(code, message, advice, 1);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._new_crash = function(code, message, advice, delta) {
    var R;
    //# when isa_jserror code, just
    ({code, message, advice, delta} = this._get_cmad.apply(this, arguments));
    if (CND.isa_jserror(code)) {
      R = code;
      if (message != null) {
        R.message = message;
      }
    } else {
      R = new Error(message);
      R.code = code;
    }
    //.........................................................................................................
    if (R.message == null) {
      R.message = '';
    }
    if (!R.message.startsWith('CRASH code: ')) {
      R.message = `CRASH code: ${rpr(code)}\n${message}`;
    }
    R.advice = advice;
    R.location = get_location(delta + 1);
    R['~isa'] = 'HSB/crash';
    //.........................................................................................................
    return R;
  };

  //===========================================================================================================
  // EXCEPTION HANDLING
  //-----------------------------------------------------------------------------------------------------------
  exit_codes = {
    error: 1,
    crash: 2,
    notfound: 127
  };

  //-----------------------------------------------------------------------------------------------------------
  this.exit_handler = function(exception) {
    var head, i, len, line, message, print, ref, ref1, ref2, tail;
    // throw exception unless @is_error exception
    debug('55567', rpr(exception));
    // throw exception unless @is_crash exception
    if (this.is_crash(exception)) {
      print = warn;
      message = (ref = exception.message) != null ? ref : "CRASH code: crash\nan unrecoverable condition occurred";
      [head, ...tail] = message.split('\n');
    } else {
      print = alert;
      message = 'ROGUE EXCEPTION: ' + ((ref1 = exception.message) != null ? ref1 : "an unrecoverable condition occurred");
      [head, ...tail] = message.split('\n');
    }
    print(CND.reverse(' ' + head + ' '));
    for (i = 0, len = tail.length; i < len; i++) {
      line = tail[i];
      warn(line);
    }
    /* TAINT should have a way to set exit code explicitly */
    whisper(exception.stack);
    return process.exit((ref2 = exit_codes[exception.code]) != null ? ref2 : exit_codes['error']);
  };

  // #-----------------------------------------------------------------------------------------------------------
  // @remove_exit_handler = -> process.removeListener 'uncaughtException', @exit_handler

  //###########################################################################################################
  (function(ME) {
    var method, name, results;
    results = [];
    for (name in ME) {
      method = ME[name];
      if (!CND.isa_function(method)) {
        continue;
      }
      results.push(ME[name] = method.bind(ME));
    }
    return results;
  })(this);

  //###########################################################################################################
// process.on 'uncaughtException', @exit_handler

// @remove_exit_handler()
// @crash 'notfound', "didn't find something"
// @crash 'oops'

}).call(this);

//# sourceMappingURL=happy-sad-bad.js.map