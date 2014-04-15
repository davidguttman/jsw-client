multilevel = require 'multilevel'
shoe = require 'shoe'

manifest = require './manifest.json'

module.exports = window.db = db = multilevel.client manifest

sock = shoe '/sock'
sock.pipe(db.createRpcStream()).pipe sock
