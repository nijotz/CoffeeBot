irc = require('./irc')
config = require('./config')

class Bot
  constructor: ->
    @connections = {}
    for server of config
      console.log "Loaded '#{ server }' config"
      host = config[server].host
      port = config[server].port
      @connections[server] = new irc.IrcConnection(host, port)
      @connections[server].connect()
      @connections[server].socket.on 'connect', @handle_connect(server)

  handle_connect: (server) =>
    return () =>
      console.log 'Setting username'
      nick = config[server].user.nick
      @connections[server].socket_write 'NICK ' + nick

      user = config[server].user.user
      real = config[server].user.real
      @connections[server].socket_write 'USER ' + user + ' 8 * :' + real

      for chan, pass of config[server].chans
        @connections[server].socket_write 'JOIN #' + chan + ' ' + pass


bot = new Bot
