Db = require 'db'
App = require 'app'
Event = require 'event'

exports.onInstall = (config) !->
	if config?
		onConfig config

exports.onConfig = onConfig = (config) !->
	if config?
		options = {}
		for k, v of config
			if k.indexOf('option') is 0
				optionId = k.substr(6, k.length)
				Db.shared.merge optionId, 'text', v
			else
				Db.shared.merge k, v

exports.client_vote = (optionId) !->
	prevOptionId = null
	if !Db.shared.get('multiple')
		Db.shared.forEach (opt) !->
			if opt.key() isnt optionId and opt.get('votes', App.userId())
				opt.remove 'votes', App.userId()

	Db.shared.modify optionId, 'votes', App.userId(), (v) -> (if v then null else true)

