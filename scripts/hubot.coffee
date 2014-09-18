# DESCRIPTION:
#   hubot の情報を表示する。
#
# COMMANDS:
#   hubot version - 現在のバージョンを表示

Path = require 'path'

module.exports = (robot) ->

  pkg = require Path.join __dirname, '..', 'package.json'

  robot.respond /version/i, (msg) ->
    msg.send "#{pkg.version} (hubot: #{robot.version})"
