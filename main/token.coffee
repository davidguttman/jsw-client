_ = require 'underscore'
ST = require 'simple-timeseries'
hypnotable = require 'hypnotable'
timedChunkStream = require '../timed-chunk.coffee'

{headlinesByToken} = require('../db.coffee').sublevels

template = require './token.jade'
style = require './token.scss'

weekMS = 7 * 24 * 3600 * 1000
firstDate = '2010-11-12'
firstMS = (new Date firstDate).valueOf()

module.exports = (token) ->
  ht = hypnotable [
    {title: 'Headline', property: 'text', template: headlineLink}
    {title: 'Topics', property: 'tokens', template: tokenLinks}
    {title: 'Issue', property: 'issue', template: issueLink}
  ]

  ht.el.classList.add 'table'
  @target.innerHTML = template token: token
  @target.querySelector('.headlines').appendChild ht.el

  rs = headlinesByToken.createReadStream
    start: token + '\xff'
    end: token + '\xff\xff'
    reverse: true

  lastIssue = Math.floor msToIssue (new Date).valueOf()
  lastIssue -= 3 # manual correction

  tsData = []
  tokenCounts = {}

  rs.pipe(timedChunkStream()).on 'data', ({key, value}) ->
    for token in value.tokens
      tokenCounts[token] ?= 0
      tokenCounts[token] += 1

    tsData[value.issue] ?= 0
    tsData[value.issue] += 1

    ht.write value

  target = @target
  rs.on 'end', ->
    topTokens = getTopTokens tokenCounts
    ttEl = target.querySelector '.top-tokens'
    ttEl.innerHTML = 'Top Co-Topics: ' + tokenLinks topTokens

    data = []
    for i in [1..lastIssue]
      ts = issueToMS i
      data.push [ts, tsData[i] or 0]

    tsEl = target.querySelector '.timeseries'
    st = new ST data,
      width: tsEl.getBoundingClientRect().width
      height: 200
      yLabel: 'mentions'

    tsEl.appendChild st.el

headlineLink = (text, headline) ->
  "<a href='#{headline.url}' target='_blank'>#{text}</a>"

tokenLinks = (tokens) ->
  tokens.map(tokenLink).join ', '

tokenLink = (token) ->
  "<a href='#/#{token}'>#{token}</a>"

issueLink = (issue) ->
  "<a href='http://javascriptweekly.com/issues/#{issue}' target='_blank'>#{issue}</a>"

issueToMS = (n) ->
  ms = (n - 1) * weekMS + firstMS

msToIssue = (ms) ->
  n = 1 + (ms - firstMS) / weekMS

getTopTokens = (tokenCounts, min = 2) ->
  topTokenArray = _.pairs tokenCounts
  topTokens = _.sortBy topTokenArray, ([token, count]) -> -count
  filtered = _.filter topTokens, ([token, count]) -> count >= min
  return filtered[1..20].map ([token, count]) -> token
