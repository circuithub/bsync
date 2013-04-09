[![build status](https://secure.travis-ci.org/circuithub/bsync.png)](http://travis-ci.org/circuithub/bsync)
bsync
=====

Async++ =)

A better/different control flow library for node.js. Designed for task-independent parallelism where specified functions are all guaranteed to execute even if some fail.

## parallel

### Example

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
    cbEach(error, data, stats, sequence, next)
      error, data -- as reported by execFunc'tion
      stats -- {completed: x, inTotal: x, withData: x, withErrors: x}
      sequence -- the sequence number (index) of the function that just completed execution; useful for referencing the input parameter data
      next -- Callback when ready to start the next execution in the series sequence (usage: next() )
    cbDone(error, stats) -- a single error object if any errors occurred, but that doesn't indicate complete failure. Check stats.
      stats -- {completed: x, inTotal: x, withData: x, withErrors: x}
###
exports.seriesEach = (execFuncs, cbEach, cbDone) ->
```

### Example

```coffeescript
#--Load Module
bsync = require "bsync"
#--Example Data to Work On
param1 = [0,1,2,3,4,5,6,7,8,9]
#--Define eachFunction; The eachFunction is called after each workFunction completes or crashes
eachFunction = (err, data, stats, sequence) ->
	console.log "[eachFunction]", err, data, stats, sequence
	console.log "The input to this function for param1 was", param1[sequence] #In case you need to reference it for retry-style operations; Make sure to keep the input data in context
	return
#--Apply Work Functions
for i in [0...10] #i = 0 to 9 using coffeescript notation
	workers.push bsync.apply theWorkFunction, param1[i], param2   #note: omit callback parameter
#--Execute Work Functions
bsync.seriesEach workers, eachFunction, (error, stats) ->
	console.log stats
```

## apply

### Example
