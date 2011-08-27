irc = require('./irc')
config = require('./config')


class Bot
  constructor: ->
    @connections = {}
    for server of config
      host = config[server].host
      port = config[server].port
      @add_connection server, host, port
      @connections[server].connect()

  add_connection: (name, host, port) =>
    @connections[name] = new irc.IRCConnection(host, port)
    @connections[name].add_listener(new irc.ConnectionListener 'connect',
      @get_handle_connect(name))
    console.log "Loaded '#{ name }' connection"

  get_handle_connect: (server) ->
    return () => @_handle_connect(server)

  _handle_connect: (server) =>
    callback = () =>
      console.log "Setting username on #{ server }"
      nick = config[server].user.nick
      @connections[server].stream_write 'NICK ' + nick

      user = config[server].user.user
      real = config[server].user.real
      @connections[server].stream_write 'USER ' + user + ' 8 * :' + real
    setTimeout callback, 2000

    callback = () =>
      for chan, pass of config[server].chans
        @connections[server].stream_write 'JOIN #' + chan + ' ' + pass
    setTimeout callback, 5000


bot = new Bot
