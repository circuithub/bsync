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