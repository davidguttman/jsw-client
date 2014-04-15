cssify = require 'cssify'
router = require 'directify'

cssify.byUrl '//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css'

top = require './main/top.coffee'
token = require './main/token.coffee'

template = require './index.jade'
search = new (require './main/search.coffee')

container = document.createElement 'div'
container.classList.add 'container'
container.innerHTML = template()
container.querySelector('.search-container').appendChild search.el
window.document.body.appendChild container

content = document.createElement 'div'
content.className = 'content row'
container.appendChild content

routes =
  '/': top
  '/:token': token

router routes, content

window.location.hash = '/' if window.location.hash is ''

onHashchange = (evt) ->
  if window.ga
    eventOpts =
      eventCategory: 'pageview'
      eventAction: window.location.hash

    window.ga 'send', 'event', eventOpts

window.addEventListener 'hashchange', onHashchange
