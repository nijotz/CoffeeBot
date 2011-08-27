net = require 'net'
tls = require 'tls'
debug = false


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

  get_event_handler: (event) ->
    return () => @handle_event(event, arguments)

  handle_event: (event, args) ->
    for listener of @listeners[event]
      @listeners[event][listener].callback args[0]

  add_listener: (listener) ->
    console.log "Adding ConnectionListener: #{ listener.event }"
    if not @listeners[listener.event]
      @listeners[listener.event] = []
    @listeners[listener.event].push listener


class Listener


class ConnectionListener extends Listener
  constructor: (@event, @callback) ->


exports.Connection = Connection
exports.Listener = Listener
exports.ConnectionListener = ConnectionListener
