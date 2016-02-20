events = require 'events'
Store = require 'dht-store'
TChannel = require 'tchannel'

defaultOptions =
	wanIp: '127.0.0.1'
	dhtPort: 6881
	tcPort: 4000
	# dht-store config
	dhtStore: {}

module.exports =
	class RPC extends events.EventEmitter
		constructor: (opts) ->
			@options = opts || {}
			for o, v of defaultOptions
				if @options[o] == undefined
					@options[o] = v

			@channel = new TChannel
			@dhtStore = new Store @options.dhtStore

			@peerChannel = @channel.makeSubChannel {serviceName: @options.wanIp + ':' + @options.tcPort}

			@peerChannel.register 'lookupUser', (req, res, userName) =>
				@emit 'lookup', userName.toString() , (exist) =>
					res.headers.as = 'raw'
					res.sendOk JSON.stringify {exist: exist}

			@peerChannel.register 'sendMessage', (req, res, recvName, message) =>
				message = JSON.parse message.toString()
				@emit 'message', recvName.toString(), message
				res.headers.as = 'raw'
				res.sendOk JSON.stringify {success: true}

			@dhtStore.on 'ready', () =>
				if @options.dhtStore.bootstrap != true
					@dhtStore.listen @options.dhtPort

				@channel.listen @options.tcPort, @options.wanIp, () =>
					@emit 'ready'


		registerUser: (name, cb) ->
			@dhtStore.kvPut name, @options.wanIp + ':' + @options.tcPort, (err, key, n) =>
				if n > 0
					cb && cb null
				else
					cb && cb err


		findUser: (name, cb) ->
			@dhtStore.kvGet name, 'utf8', (err, n, broker) =>
				if broker == null
					cb {code: 1, desc: 'not found'}
					return

				senderChannel = new TChannel
				ch = senderChannel.makeSubChannel {
					serviceName: 'sender', 
					peers: [broker],
					requestDefaults: {
						hasNoParent: true,
						headers: {'as': 'raw', 'cn': 'broker'}
					}
				}
				ch.request({
					serviceName: broker,
					timeout: 10000
				}).send 'lookupUser', name, '', (err, res, resMsg) =>
					if err
						cb err
						return

					result = JSON.parse resMsg.toString()
					if result.exist == true
						cb null, broker
					else
						cb {code: 1, desc: 'not found'}


		sendMessage: (senderName, peer, message, cb) ->
			senderChannel = new TChannel
			ch = senderChannel.makeSubChannel {
				serviceName: 'sender', 
				peers: [peer.address],
				requestDefaults: {
					hasNoParent: true,
					headers: {'as': 'raw', 'cn': 'broker'}
				}
			}
			ch.request({
				serviceName: peer.address,
				timeout: 10000
			}).send 'sendMessage', peer.name, JSON.stringify({from: senderName, content: message}), (err, res, resMsg) =>
				cb err, JSON.parse resMsg.toString()