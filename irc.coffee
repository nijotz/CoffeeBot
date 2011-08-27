net = require 'net'
connection = require './connection'
debug = true


class IRCConnection extends connection.Connection
  constructor: (@host, @port, @tls = false) ->
    super @host, @port, @tls
    @irc_listeners = []

    # On connect, add a ping response listener
    @add_listener new connection.ConnectionListener 'connect', () =>
      @add_listener new IRCConnectionListener /^PING :(.+)$/i, (match) =>
        @write 'PONG :' + match[1]
    
    # Parse network data events for the IRCConnectionListener
    @read (data) =>
      msgs = data.split '\r\n'
      for msg in msgs
        console.log "#{ @host }:#{ @port } - RECV -", msg
        if msg then @handle_event(new IRCConnectionEvent msg)

  handle_event: (event) =>
    if debug then console.log "#{ event instanceof IRCConnectionEvent }"

    if not (event instanceof IRCConnectionEvent)
      super event

    for i in [0...@irc_listeners.length]
      listener = @irc_listeners[i]
      match = listener.regex.exec event.msg
      if match
        listener.callback match
      if listener.once
        @irc_listeners.slice i,1

  add_listener: (listener) ->
    if listener instanceof connection.ConnectionListener
      super listener
    if listener instanceof IRCConnectionListener
      @irc_listeners.push listener

  connect: ->
    console.log "Connecting to #{ @host }:#{ @port }..."
    super

  read: (callback) ->
    @add_listener new connection.ConnectionListener 'data', callback

  write: (msg) ->
    console.log "#{ @host }:#{ @port } - SENT -", msg
    super msg


class IRCConnectionListener extends connection.ConnectionListener
  constructor: (@regex, @callback, once = false) ->


class IRCConnectionEvent extends connection.ConnectionEvent
  constructor: (@msg) ->


exports.IRCConnection = IRCConnection
exports.IRCConnectionEvent = IRCConnectionEvent
exports.IRCConnectionListener = IRCConnectionListener
exports.ConnectionListener = connection.ConnectionListener
