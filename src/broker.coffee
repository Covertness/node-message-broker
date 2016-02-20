events = require 'events'
socketio = require 'socket.io'
LRU = require 'lru'
RPC = require './rpc'

defaultOptions =
	# max items count
	maxClients: 10000

module.exports =
	class Broker extends events.EventEmitter
		constructor: (opts) ->
			@options = opts || {}
			for o, v of defaultOptions
				if @options[o] == undefined
					@options[o] = v

			@rpc = new RPC @options

			@rpc.on 'ready', () =>
				@routeTable = new LRU {max: @options.maxClients}
				@io = new socketio()

				@routeTable.on 'evict', (item) =>
					console.log 'route table is full'
					evictedClient = item.value
					evictedClient.disconnect()

				@io.on 'connection', (client) =>
					clientInfo = null
					client.on 'login', (info, cb) =>
						clientInfo = info
						@handleLogin clientInfo, client, cb

					client.on 'find', (user, cb) =>
						@handleFind user, cb

					client.on 'send', (peer, message, cb) =>
						@handleSend clientInfo, peer, message, cb

					client.on 'disconnect', () =>
						@handleDisconnect clientInfo

				@io.listen @options.socketioPort
				@emit 'ready'

			@rpc.on 'message', (recvName, message) =>
				@handleMessage recvName, message

			@rpc.on 'lookup', (userName, cb) =>
				@handleLookup userName, cb


		close: () ->
			@io.close()


		handleLogin: (user, client, cb) ->
			if user.name == undefined
				cb && cb 'user name is required'
				return

			console.log 'new user:', user.name

			@rpc.registerUser user.name, (err) =>
				if err
					cb && cb err
					return

				@routeTable.set user.name, client
				cb && cb null, user


		handleFind: (user, cb) ->
			if user.name == undefined
				cb 'user name is required'
				return

			@rpc.findUser user.name, (err, broker) =>
				cb err, broker


		handleSend: (user, peer, message, cb) ->
			if user == null or user.name == undefined or peer == undefined or message == undefined
				cb 'invalid message'
				return

			@rpc.sendMessage user.name, peer, message, (err, result) =>
				if err
					cb err
					return

				cb null, result


		handleDisconnect: (user) ->
			if user and user.name
				console.log 'user disconnect:', user.name

				@routeTable.remove user.name


		handleMessage: (recvName, message) ->
			client = @routeTable.get recvName
			if client == undefined
				return

			client.emit 'message', message.from, message.content


		handleLookup: (userName, cb) ->
			client = @routeTable.get userName
			cb !(client == undefined)