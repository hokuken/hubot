# Description:
#   hubot に誰かが何に似てるか教えたり聞いたりする
#
# Commands:
#   hubot xxx looks like keyword
#   hubot who does xxx look like?
#   hubot xxx does not look like anyone

module.exports = (robot) ->

  robot.respond /([a-z0-9]+) looks like (.+)/i, (msg) ->
    user_name = msg.match[1]
    what = msg.match[2]
    room = msg.message.room
    msg.query = what
    robot.brain.data.lookslike = {} unless robot.brain.data.lookslike
    robot.brain.data.lookslike[user_name] = what
    robot.brain.save
    msg.send "OK. #{user_name} looks like #{what}"
    robot.emit "image:get", msg, room
  robot.respond /who does ([a-z0-9]+) look like\??/i, (msg) ->
    user_name = msg.match[1]
    if robot.brain.data.lookslike[user_name]
      what = robot.brain.data.lookslike[user_name]
      room = msg.message.room
      msg.query = what
      msg.send "#{user_name} looks like *#{what}*"
      robot.emit "image:get", msg, room
    else
      msg.send "I don't know who does #{user_name} looks like..."
  robot.respond /([a-z0-9]+) does not look like anyone/i, (msg) ->
    user_name = msg.match[1]
    delete robot.brain.data.lookslike[user_name]
    msg.send "OK. #{user_name} has Absolutely Unique Face!!!"
