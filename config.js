module.exports = {
	// WAN IP address
	wanIp: '127.0.0.1',
	// Socket.IO port
	socketioPort: 3000,
	// DHT port
	dhtPort: 6881,
	dhtStore: {
		// connect other nodes when bootstrap is true
		bootstrap: false,
		nodes: [
			// {host: 'router.bittorrent.com', port: 6881}
		]
	}
};