[![build status](https://secure.travis-ci.org/circuithub/bsync.png)](http://travis-ci.org/circuithub/bsync)
bsync
=====

Async++

## seriesWith

Executes specified functions in series

Useful for maintenance tasks where executions are sequenced for reasons other than logical control flow (such as bandwidth limitations) -- e.g. when each execution is independent. 

seriesEach guarantees that each specified function executes in order and that *all functions* execute even if prior calls report errors.

```coffeescript
###
  Execute functions in series calling cbEach() after each function executes
  ---
  Input (parameters)
    execFuncs -- Array of applied functions (use bsync.apply)
    cbEach -- Callback after each execution of a specified function
    cbDone -- Final callback when execution of all functions is complete
  Output (calls)
    cbEach(error, data, stats)
      error, data -- as reported by execFunc'tion
      stats -- {completed: x, inTotal: x, withData: x, withErrors: x}
    cbDone(error, stats) -- a single elma error object if any errors occurred, but that doesn't indicate complete failure. Check stats.
      stats -- {completed: x, inTotal: x, withData: x, withErrors: x}
###
exports.seriesEach = (execFuncs, cbEach, cbDone) ->
```

### Example

```coffeescript
#--Load Module
bsync = require "bsync"
#--Define eachFunction; The eachFunction is called after each workFunction completes or crashes
eachFunction = (err, data, stats) ->
	console.log "[eachFunction]", err, data, stats
	return
#--Apply Work Functions
for i in [0...10]
	workers.push bsync.apply theWorkFunction, param1, param2   #note: omit callback parameter
#--Execute Work Functions
bsync.seriesEach workers, eachFunction, (error, stats) ->
	console.log stats
```