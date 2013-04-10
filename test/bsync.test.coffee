should = require "should"

bsync = require "../lib/bsync"

#callback has only 1 data param
#result = boolean to pass back as result
#error = boolean; if true returns error message.
testFunction = (result, param1, param2, error, cbDone) ->
  if error
    cbDone ["errorMessage"]
    return
  cbDone undefined, result

eachFunction = (err, data, stats, sequence, next) ->
  console.log "[eachFunction]", err, data, stats, sequence
  next()

NUM_FUNCS_TO_TEST = 5

describe "bsync", ->
  describe "#seriesEach", ->
    it "should handle mixed succeed/fail cases", (done) ->      
      workers = []
      for i in [0...10]
        workers.push bsync.apply testFunction, i, 1, 2, i%3 is 0
      bsync.seriesEach workers, eachFunction, (error, stats) ->
        should.exist error
        should.exist stats
        stats.withData.should.equal 6
        stats.withErrors.should.equal 4
        console.log "Done!"
        done()

  describe "#parallel", ->

    describe "--Object", ->
      it "should handle multi-param all-succeed cases", (done) ->
        workerObject = {
          keyA: bsync.apply(testFunction, true, "keyA.param1", "keyA.param2", false) 
          keyB: bsync.apply(testFunction, true, "keyB.param1", "keyB.param2", false) 
        }              
        bsync.parallel workerObject, (allErrors, allResults) ->        

          # existance
          should.not.exist allErrors
          should.exist allResults    
          should.exist allResults.keyA
          should.exist allResults.keyB          

          # outer results structure
          allResults.should.be.an.instanceOf(Object) # (Must be a circuithub error)        
          should.equal Object.keys(allResults).length, 2                  

          # data
          allResults.keyA.should.be.true
          allResults.keyB.should.be.true

          done()        

      it "should handle functions when all fail", (done) ->
        workerObject = {
          keyA: bsync.apply(testFunction, true, "keyA.param1", "keyA.param2", true) 
          keyB: bsync.apply(testFunction, true, "keyB.param1", "keyB.param2", true) 
        }                   
        bsync.parallel workerObject, (allErrors, allResults) ->                
          should.exist allErrors
          should.not.exist allResults                 
          allErrors.keyA[0].should.equal "errorMessage"     
          allErrors.keyB[0].should.equal "errorMessage"       
          done()       
   
      it "should handle functions when some succeed and some fail", (done) ->
        workerObject = {
          keyA: bsync.apply(testFunction, true, "keyA.param1", "keyA.param2", false) 
          keyB: bsync.apply(testFunction, false, "keyB.param1", "keyB.param2", true) 
        }                   
        bsync.parallel workerObject, (allErrors, allResults) ->                
          # successes
          should.exist allResults                    
          allResults.keyA.should.be.true          
          # failures
          should.exist allErrors                  
          allErrors.keyB[0].should.equal "errorMessage"       
          done()    
        
    describe "--Array", ->
      it "should handle functions with multiple parameters that don't fail (e.g. doesn't return errors)", (done) ->  
        workerFunctions = []
        for i in [0...NUM_FUNCS_TO_TEST]
          param1 = "Function Number #{i}, Input Parameter 1"
          param2 = "Function Number #{i}, Input Parameter 2"        
          workerFunctions.push bsync.apply(testFunction, true, param1, param2, false) 
        bsync.parallel workerFunctions, (allErrors, allResults) ->        

          # existance
          should.not.exist allErrors
          should.exist allResults              

          # outer results structure
          allResults.should.be.an.instanceof(Array) # (Must be a circuithub error)        
          allResults.should.not.be.empty        
          should.equal allResults.length, NUM_FUNCS_TO_TEST            

          # data
          allResults[0].should.be.true

          done()        

      it "should handle functions when all fail", (done) ->
        workerFunctions = []
        for i in [0...NUM_FUNCS_TO_TEST]
          param1 = "Function Number #{i}, Input Parameter 1"
          param2 = "Function Number #{i}, Input Parameter 2"        
          workerFunctions.push bsync.apply(testFunction, true, param1, param2, true) 
        bsync.parallel workerFunctions, (allErrors, allResults) ->                
          should.exist allErrors
          should.exist eachRow for eachRow in allErrors
          should.not.exist allResults              
          done()        

      it "should handle functions when some fail and some succeed", (done) ->  

        workerFunctions = []
        for i in [0...NUM_FUNCS_TO_TEST]
          param1 = "p#{i}-1"
          param2 = "p#{i}-2"        
          # even numbered functions fail
          if i%2 is 0
            workerFunctions.push bsync.apply(testFunction, true, param1, param2, true) 
          else
            workerFunctions.push bsync.apply(testFunction, true, param1, param2, false) 
        bsync.parallel workerFunctions, (allErrors, allResults) ->        

          # errors
          should.exist allErrors        
          for errs in allErrors
            if errs?
              should.exist errs

          # successes
          should.exist allResults              
     
          # inner results structure
          for i in [0...allResults.length]
            if i%2 is 0
              #failed            
              should.exist allErrors[i] #e.g. it should have failed      
              should.exist allErrors[i]
              should.not.exist allResults[i]
            else            
              #succeeded
              should.not.exist allErrors[i]
              allResults[i].should.be.true
          done()        

  describe "#failed", ->
    it "should have a test"
