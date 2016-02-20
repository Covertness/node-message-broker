var Broker = require('./lib/broker')
  , config = require('./config');

var broker = new Broker(config);

broker.on('ready', function () {
	console.log('The broker is listening on', config.socketioPort);
});
