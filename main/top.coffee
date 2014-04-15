hypnotable = require 'hypnotable'
timedChunkStream = require '../timed-chunk.coffee'

db = require '../db.coffee'
{tokensByScore} = db.sublevels

template = require './top.jade'

module.exports = ->
  ht = hypnotable [
    {title: 'Topic', property: 'token', template: tokenLink}
    {title: '# Issues', property: 'score'}
  ]

  ht.el.classList.add 'table'
  @target.innerHTML = template()

  @target.appendChild ht.el

  rs = tokensByScore.createKeyStream
    reverse: true
    limit: 1000

  tcs = timedChunkStream()

  rs.pipe tcs

  tcs.on 'data', (key) ->
    [scoreStr, token] = key.split '\xff'
    row = token:token, score: parseFloat scoreStr
    ht.write row

  # tcs.on 'end', ->

tokenLink = (token) ->
  "<a href='#/#{token}'>#{token}</a>"
