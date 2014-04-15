es = require 'event-stream'

module.exports = timedChunkStream = ->
  lastBreak = Date.now()

  tcs = es.through (data) ->
    @queue data

    now = Date.now()
    if now - lastBreak > 50
      tcs.pause()
      setTimeout ->
        tcs.resume()
      , 25
