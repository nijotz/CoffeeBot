net = require 'net'
tls = require 'tls'
debug = true


class Connection
  constructor: (@host, @port, @tls = false) ->
    @listeners = {}

  connect: ->
    console.log 'Connecting...'
    if @tls
      @stream = tls.connect(@port, @host)
      @stream.on 'secureConnection', @get_event_handler('connect')
    else
      @stream = new net.Socket()
      @stream.setNoDelay
      @stream.on 'timeout', @get_event_handler('timeout')
      @stream.on 'connect', @get_event_handler('connect')
      @stream.connect @port, @host

    @stream.setEncoding('ascii')
    # No way to listen to all? Gotta do 'em all individually
    @stream.on 'data', @get_event_handler('data')
    @stream.on 'end', @get_event_handler('end')
    @stream.on 'error', @get_event_handler('error')
    @stream.on 'close', @get_event_handler('close')
    @stream.on 'drain', @get_event_handler('drain')

    @add_listener new ConnectionListener 'connect', () =>
      console.log "Connected!"

    @add_listener new ConnectionListener 'error', (e) =>
      console.log "Error: #{ e }"

  get_event_handler: (type) ->
    if debug then console.log "Adding event handler #{ type }"
    return () => @handle_event new ConnectionEvent type, arguments

  handle_event: (event) ->
    if debug then console.log "Handling event #{ event.type }"
    for i of @listeners[event.type]
      listener = @listeners[event.type][i]
      listener.callback.apply(this, event.args)
      if listener.once
        @listeners[event.type].slice i,1

  add_listener: (listener) ->
    if debug then console.log "Adding listener #{ listener.event }"
    if not @listeners[listener.event]
      @listeners[listener.event] = []
    @listeners[listener.event].push listener

  read: (callback) ->
    if debug then console.log "Setting read callback"
    @add_listener new ConnectionListener 'data', callback

  write: (msg) ->
    if debug then console.log "Writing"
    if @stream.writable
      @stream.write msg + '\n', () =>
    else
      @add_listener new ConnectionListener 'drain', () =>
        @write msg


class Event
  constructor: () ->


class ConnectionEvent extends Event
  constructor: (@type, @args) ->


class Listener
  constructor: (@once = false) ->


class ConnectionListener extends Listener
  constructor: (@event, @callback, @once = false) ->


exports.Connection = Connection
exports.ConnectionEvent = ConnectionEvent
exports.ConnectionListener = ConnectionListener
