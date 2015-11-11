Db = require 'db'
Plugin = require 'plugin'
Event = require 'event'

exports.getTitle = ->
	Db.shared.get 'question'

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
			if opt.key() isnt optionId and opt.get('votes', Plugin.userId())
				opt.remove 'votes', Plugin.userId()

	Db.shared.modify optionId, 'votes', Plugin.userId(), (v) -> (if v then null else true)

