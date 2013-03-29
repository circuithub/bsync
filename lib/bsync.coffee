#**parallel** - Sync version of async.parallel
#    1. Does not return until all functions succeed or fail (true synchronization)
#    2. The index-order of the functions is maintained between input and output
#    3. Return values do not exist if universally applied (e.g. there will be no error object if all functions succeed)   
#    4. More robust than async.parallel
#+ *parallelFuncs* - array of functions to execute in parallel (use bsync.apply to parametricize)  
#+ *cbEventName(allErrors, allResults)* - This is the callback      
#    + *allErrors* - 
#    + *allResults* -   
exports.parallel = (parallelFuncs, callback) ->
  allErrors = if Array.isArray parallelFuncs then new Array parallelFuncs.length else {}
  allResults = if Array.isArray parallelFuncs then new Array parallelFuncs.length else {}
  keys = if Array.isArray parallelFuncs then [0...parallelFuncs.length] else Object.keys(parallelFuncs)  
  if keys.length == 0
    callback undefined, if Array.isArray parallelFuncs then [] else {}
    return
  counter = keys.length 
  blockUntilFinished = (index) -> (errors, results) ->
    if errors
      allErrors[index] = errors
    if results
      allResults[index] = results
    --counter
    if counter == 0
      numErrored = 0      
      numErrored++ for i in keys when allErrors[i]?           
      if numErrored is 0        
        callback undefined, allResults
      else        
        if numErrored is keys.length
          # all failed
          callback allErrors, undefined
        else
          # only some failed
          callback allErrors, allResults
    return

  for i in keys
    f = parallelFuncs[i]
    f blockUntilFinished i
  return

exports.apply = (fn) ->
  args = Array.prototype.slice.call(arguments, 1)
  return () ->
    return fn.apply null, args.concat(Array.prototype.slice.call(arguments))

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
  idx = 0; numData = 0; numErrors = 0;
  stats = (i) ->
    return {completed: i+1, inTotal: execFuncs.length, withData: numData, withErrors: numErrors}
  fn = (i) ->
    try
      execFuncs[i] (err, data) ->
        numErrors++ if err? 
        numData++ if data?
        cbEach err, data, stats(i)
        setImmediate sv
    catch error
      cbEach error, undefined, stats(i)
      setImmediate sv
  sv = () ->
    if idx >= execFuncs.length
      error = if numErrors > 0 then new Error "Series execution resulted in #{numErrors} instances reporting errors." else undefined
      cbDone error, stats(execFuncs.length-1)
      return        
    fn idx
    idx++
    return
  sv(); return
