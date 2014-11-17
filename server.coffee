Db = require 'db'
Plugin = require 'plugin'
Event = require 'event'

exports.getTitle = ->
	Db.shared.get 'question'

exports.onInstall = (config) !->
	if config?
		onConfig config

		Event.create
			unit: 'other'
			text: "#{Plugin.userName(Plugin.ownerId())} added a poll: #{config.question}"
			new: ['all', -Plugin.ownerId()]

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
	# Remove the current vote (if any)
	prevOptionId = null
	log 'plugin userId -->', Plugin.userId()
	Db.shared.forEach (option) !->
		if option.get('votes', Plugin.userId())
			prevOptionId = option.key()
			option.remove 'votes', Plugin.userId()

	if prevOptionId isnt optionId
		Db.shared.set optionId, 'votes', Plugin.userId(), true

