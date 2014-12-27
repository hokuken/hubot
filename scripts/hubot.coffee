# DESCRIPTION:
#   hubot の情報を表示する。
#
# CONFIGURATION:
#   HUBOT_TOKEN - token of secret action
#   HUBOT_NOTIFICATION_CHANNEL - channel for notifying
# COMMANDS:
#   hubot version - 現在のバージョンを表示

Path = require 'path'
Semver = require 'semver'

module.exports = (robot) ->

  messages = [
    "(´-`).oO(ここ、俺の部屋なんやけどなー)"
    "( ´ ▽ ` )ﾉ ﾀﾀﾞｲﾏｧ 出かけてました！"
    "あ、これは勉強になるなぁー"
    ":rage4: 今のは痛かった…痛かったぞーーー！！！"
    "私の戦闘力は53万です"
  ]

  robot.hear /./i, (msg) ->
    return unless msg.envelope.room is "hubot"
    return if Math.random() * 10 > 2
    msg.send msg.random messages

  robot.respond /version/i, (msg) ->
    pkg = require Path.join __dirname, '..', 'package.json'
    msg.send "#{pkg.version} (hubot: #{robot.version})"

  robot.router.post "/hubot/deployed", (req, res) ->
    query = req.query
    body = req.body
    unless process.env.HUBOT_TOKEN? and process.env.HUBOT_TOKEN in [query.token, body.token]
      res.writeHead 403
      res.end "NG"
      return

    pkg = require Path.join __dirname, '..', 'package.json'

    unless robot.brain.data.hubot
      robot.brain.data.hubot = {
        lastVersion: pkg.version
      }
      return

    if Semver.gt pkg.version, robot.brain.data.hubot.lastVersion
      robot.brain.data.hubot.lastVersion = pkg.version
      message = "@everyone #{robot.name}は年末年始モードに切り替わりました。\n" +
                "ちょっと静かにしてます（笑）\n" +
                "もちろん常駐してるので声かけてくださいねー :sleeping:\n" +
                "ではでは、良いお年を！ :smile_cat:"
      # message = "@everyone 新しい#{robot.name}に生まれ変わりました。\n" +
      #   "バージョンは #{pkg.version} です！\n\n" +
      #   "回覧板を回すコマンドを追加しましたー！\n" +
      #   "`#{robot.name} 回覧板を回して`\n" +
      #   "ベータ版と違ってできるだけチャンネルを汚さないように気をつけました。\n" +
      #   "ユーザーも指定できるのでぜひご利用ください！"
      room = process.env.HUBOT_NOTIFICATION_CHANNEL or null
      robot.send {room: room}, message
    res.end "OK"
