net = require 'net'
connection = require './connection'


class IRCConnection extends connection.Connection
  constructor: (@host, @port, @tls = false) ->
    super @host, @port, @tls
    @irc_listeners = []

    # On connect, add a ping response listener
    @add_listener new connection.ConnectionListener 'connect', () =>
      @add_listener new IRCListener /^PING :(.+)$/i, (match) =>
        @stream_write 'PONG :' + match[1]
    
    # Parse network data events for the IRCListeners
    @add_listener new connection.ConnectionListener 'data', (data) =>
        msgs = data.split '\n'
        for msg in msgs
          msg = msg.slice(0,-1) # gets rid of some weird CR character
          console.log "#{ @host }:#{ @port } - RECV -", msg
          if msg then @handle_irc_event msg

  handle_irc_event: (msg) =>
    for listener in @irc_listeners
      match = listener.regex.exec msg
      if match
        listener.callback match

  add_listener: (listener) ->
    console.log "Adding listener: #{ listener }"
    if listener instanceof connection.ConnectionListener
      super listener
    if listener instanceof IRCListener
      console.log "Adding IRCListener"
      @irc_listeners.push listener

  connect: ->
    console.log "Connecting to #{ @host }:#{ @port }..."
    super

  stream_write: (msg) ->
    @stream.write msg + '\n', () =>
      console.log "#{ @host }:#{ @port } - SENT -", msg


class IRCListener extends connection.Listener
  constructor: (@regex, @callback) ->


exports.IRCConnection = IRCConnection
exports.Listener = connection.Listener
exports.ConnectionListener = connection.ConnectionListener
exports.IRCListener = IRCListener
