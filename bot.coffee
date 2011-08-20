net = require 'net'
config = require './config'
redis = require 'redis'

class Bot
  constructor: ->
    @setup_socket()
    @listeners = []

  setup_socket: ->
    @socket = new net.Socket()
    @socket.setEncoding 'ascii'
    @socket.setNoDelay
    @socket.on 'data', @handle_network_data
    @socket.on 'connect', @handle_connect

  handle_network_data: (data) =>
    msgs = data.split '\n'
    for msg in msgs
      msg = msg.slice(0,-1) # gets rid of some weird CR character
      console.log 'RECV -', msg
      if msg then @handle_irc_msg msg

  handle_irc_msg: (msg) =>
    for listener in @listeners
      match = listener.regex.exec msg
      if match?
        listener.callback match

  handle_connect: =>
    console.log 'Established connection.'
    @add_listener new Listener(/^PING :(.+)$/i, (match) =>
      @socket_write 'PONG :' + match[1])

    @socket_write 'NICK ' + config.user.nick
    @socket_write 'USER ' + config.user.user + ' 8 * :' + config.user.real

    for chan, pass of config.chans
      @join_channel chan, pass

  add_listener: (listener) ->
    @listeners.push listener

  connect: ->
    @socket.connect config.server.port, config.server.addr
    console.log 'Connecting...'

  socket_write: (msg) ->
    @socket.write msg + '\n', 'ascii', () ->
      console.log 'SENT -', msg

  join_channel: (channel, password) ->
    @socket_write 'JOIN #' + channel + ' ' + password


class Listener
  constructor: (@regex, @callback) ->

bot = new Bot
bot.connect()
