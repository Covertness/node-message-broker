# node-message-broker

A decentralized message passing broker based on [DHT](http://www.bittorrent.org/beps/bep_0005.html), [TChannel](https://github.com/uber/tchannel-node) and [Socket.IO](http://socket.io/). [Here](http://covertness.github.io/chat/) is a simple web demo.

## Features
- Decentralized

## Usage

### Configure
Configure the wan ip and the nodes you want to join in the file [config.js](config.js).

### Start the node
```bash
$ apt-get install nodejs npm make g++
$ make init
$ make build
$ node index.js
```

### Setup the client
Passing the messages through the Socket.IO protocol. Check out the [demo](http://covertness.github.io/chat/) for more details.

## Topology
![](topology.png)
