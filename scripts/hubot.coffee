# DESCRIPTION:
#   hubot の情報を表示する。
#
# CONFIGURATION:
#   HUBOT_TOKEN - token of secret action
#   HUBOT_NOTIFICATION_CHANNEL - channel for notifying
# COMMANDS:
#   hubot version - 現在のバージョンを表示

Path = require 'path'

module.exports = (robot) ->

  pkg = require Path.join __dirname, '..', 'package.json'

  robot.respond /version/i, (msg) ->
    msg.send "#{pkg.version} (hubot: #{robot.version})"

  robot.router.post "/hubot/deployed", (req, res) ->
    body = req.body
    unless process.env.HUBOT_TOKEN is body.token
      res.writeHead 403
      res.end "NG"
      return

    message = "おまえら新しい俺様がデプロイされたぞこらぁ！\n" +
      "バージョンは #{pkg.version} だぞたここらぁ！"
    room = process.env.HUBOT_NOTIFICATION_CHANNEL
    robot.send {room: room}, message
    res.end "OK"
