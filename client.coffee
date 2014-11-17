Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Loglist = require 'loglist'
Obs = require 'obs'
Plugin = require 'plugin'
Time = require 'time'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Form = require 'form'
{tr} = require 'i18n'

exports.render = !->
	shared = Db.shared
	userId = Plugin.userId()
	ownerId = Plugin.ownerId()
	isAnonymous = Db.shared.get('anonymous')

	Dom.div !->
		Dom.style backgroundColor: '#fff', margin: '-4px -8px', padding: '8px', borderBottom: '2px solid #ccc'

		Dom.div !->
			Dom.style Box: true
			Dom.h1 shared.get('question')||tr("No question configured")

		Dom.div !->
			Dom.style marginBottom: '16px'
			if info = shared.get('info')
				Dom.richText info

		totalVotes = Obs.create(0)
		Obs.observe !->
			log 'totalVotes', totalVotes.get()

		optionsCount = 0
		empty = Obs.create(true)
		Db.shared.observeEach (option) !->
			empty.set(!++optionsCount)
			Obs.onClean !->
				empty.set(!--optionsCount)

			# track total votes count
			option.ref('votes')?.observeEach (id) !->
				totalVotes.incr()
				Obs.onClean !->
					totalVotes.incr(-1)

			Dom.div !->
				Dom.style Box: 'middle center'

				chosen = option.get('votes', userId)
				Dom.div !->
					Dom.style
						Box: 'center middle'
						width: '28px'
						height: '28px'
						borderRadius: '16px'
						border: '1px solid '+(if chosen then Plugin.colors().highlight else '#aaa')
						backgroundColor: (if chosen then Plugin.colors().highlight else 'inherit')
						color: '#fff'
						marginRight: '8px'

						if option.get('votes', userId)
							Dom.text "✓"

				Dom.div !->
					perc = 100 * (option.count('votes').get() / totalVotes.get())
					Dom.style
						Box: 'middle'
						Flex: 1
						padding: '8px'
						minHeight: '26px'
						background_: "linear-gradient(left, #ddd #{perc}%, #fff #{perc}%)"
						fontSize: '120%'
						border: '1px solid '+(if chosen then Plugin.colors().highlight else '#aaa')
						color: (if chosen then Plugin.colors().highlight else 'inherit')
						borderRadius: '2px'
						margin: '4px 0'

					Dom.div !->
						Dom.style Flex: 1
						Dom.text option.get('text')

				Dom.div !->
					c = option.count('votes').get()
					Dom.style
						Box: 'center middle'
						width: '42px'
						height: '42px'
						marginLeft: '8px'
						border: '1px solid '+(if c and !isAnonymous then Plugin.colors().highlight else '#fff')
						color: (if c then (if isAnonymous then 'gray' else Plugin.colors().highlight) else '#ccc')
						fontWeight: (if c then 'bold' else 'normal')
						borderRadius: '2px'
					Dom.span c+'x'
					Dom.onTap !->
						if isAnonymous
							Modal.show tr("Anonymous voting"), tr("Voting on this poll is anonymous")
						else if !c
							Modal.show tr("No votes"), tr("The option '%1' hasn't received any votes yet", option.get('text'))
						else
							Modal.show tr("Votes by"), !->
								Dom.style width: '80%'
								Dom.div !->
									Dom.style
										maxHeight: '40%'
										overflow: 'auto'
										_overflowScrolling: 'touch'
										backgroundColor: '#eee'
										margin: '-12px'
									option.ref('votes').observeEach (voter) !->
										Ui.item !->
											Ui.avatar Plugin.userAvatar voter.key()
											Dom.div !->
												Dom.style marginLeft: '4px'
												Dom.text Plugin.userName voter.key()

				Dom.onTap
					highlight: false,
					cb: !->
						Server.sync 'vote', option.key(), !->
							prevOptionId = null
							Db.shared.forEach (option) !->
								if option.get('votes', userId)
									prevOptionId = option.key()
									option.remove 'votes', userId

							if prevOptionId isnt option.key()
								Db.shared.set option.key(), 'votes', userId, true
					
		, (option) -> # filter/sort function
			if +option.key() and option.get('text')
				log 'option text', option.get('text')
				+option.key()

		Obs.observe !->
			if empty.get()
				Dom.div !->
					Dom.style
						padding: '12px 6px'
						textAlign: 'center'
						color: '#bbb'
					Dom.text tr("No options")

		Dom.div !->
			Dom.style
				fontSize: '70%'
				color: '#aaa'
				padding: '16px 0 0'
			Dom.text tr("Added by %1", Plugin.userName(ownerId))
			Dom.text " • "
			Time.deltaText Plugin.created()

	Dom.div !->
		Dom.style margin: '0 -8px'
		require('social').renderComments()

exports.renderSettings = !->
	Form.input
		name: 'question'
		text: tr 'Question'
		value: Db.shared.func('question') if Db.shared

	Form.text
		name: 'info'
		text: tr 'Additional info (optional)'
		autogrow: true
		value: Db.shared.func('info') if Db.shared
		inScope: !->
			Dom.prop 'rows', 1

	Form.label !->
		Dom.style margin: '10px 0'
		Dom.text tr("Poll options")

	e = Form.hidden 'count', (if Db.shared then Db.shared.get('count')||2 else 2)
	optionsCount = Obs.create(+e.value())
	Obs.observe !->
		e.value optionsCount.get()

	Loglist.render 1, optionsCount, (num) !->
		Dom.div !->
			Dom.style Box: 'middle'

			Dom.div !->
				Dom.style
					Box: 'center middle'
					width: '28px'
					height: '28px'
					borderRadius: '16px'
					border: '1px solid #aaa'
					marginRight: '8px'

			Dom.div !->
				Dom.style
					Box: 'middle'
					Flex: 1
					padding: '8px'
					minHeight: '26px'
					fontSize: '120%'
					border: '1px solid #aaa'
					borderRadius: '2px'
					margin: '4px 0'

				Form.input
					simple: true
					name: 'option'+num
					text: tr("+ Add option %1", num)
					value: Db.shared.func(num, 'text') if Db.shared
					onChange: (v) !->
						if (v||'').trim() and num is optionsCount.peek()
							optionsCount.incr()
					inScope: !->
						Dom.style
							Flex: 1
							borderBottom: '1px solid #aaa'
							display: 'block'
							border: 'none'

	Form.check
		name: 'anonymous'
		text: tr("Voting is anonymous")
		value: Db.shared.func('anonymous') if Db.shared
		inScope: !->
			Dom.style
				marginTop: '12px'
				borderTop: '1px solid #ddd'
				borderBottom: '1px solid #ddd'
