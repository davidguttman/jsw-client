bean = require 'bean'

template = require './search.jade'
style = require './search.scss'

Fuse = require 'fuse.js'
timedChunk = require '../timed-chunk.coffee'

db = require '../db.coffee'
{tokensByScore} = db.sublevels

Search = module.exports = (@opts={}) ->
  @el = document.createElement 'div'
  @setEvents()

  @createFuse()

  @render()
  return this

Search::setEvents = ->
  events = [
    ['keyup', 'input', @onKeyUp]
  ]

  for event in events
    [type, selector, handler] = event
    bean.on @el, type, selector, handler.bind this

  bean.on document, 'mouseup', @windowClick.bind this

Search::render = ->
  @el.innerHTML = template()
  return this

Search::onKeyUp = ->
  term = @el.querySelector('input').value
  if @fuse
    rawResults = @fuse.search term
    results = rawResults[0..10].map (raw) ->
      result = raw.item.token
    @setResults results
  else
    console.log 'not ready yet'

Search::createFuse = ->
  self = this

  @tokens = []
  rs = tokensByScore.createKeyStream reverse: true, limit: 2000

  tc = timedChunk()
  rs.pipe tc

  tc.on 'data', (key) ->
    [scoreStr, token] = key.split '\xff'
    self.tokens.push token: token

  tc.on 'end', ->
    self.fuse = new Fuse self.tokens,
      keys: ['token']
      shouldSort: true
      includeScore: true

Search::setResults = (results) ->
  searchResults = @el.querySelector '.search-results'
  if results.length > 0
    searchResults.style.display = 'block'
  else
    searchResults.style.display = 'none'

  searchResults.innerHTML = ''
  for result in results
    li = document.createElement 'li'
    li.innerHTML = tokenLink result
    searchResults.appendChild li

Search::hideResults = ->
  searchResults = @el.querySelector '.search-results'
  searchResults.style.display = 'none'

Search::windowClick = (evt) ->
  if evt.target is @el.querySelector 'input'
    @onKeyUp()
  else
    @hideResults()

tokenLink = (token) ->
  "<a href='#/#{token}'>#{token}</a>"
