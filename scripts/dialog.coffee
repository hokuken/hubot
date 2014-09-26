# Description:
#   Dialog test

Path = require "path"
Dialog = require Path.join __dirname, "..", "src", "dialog"

module.exports = (robot) ->

  # robot.hear /.*/i, (msg) ->
  #   dialog = Dialog.getDialog msg.envelope.user.name, msg.envelope.room
  #   console.log dialog
  #   dialog?.callback.call dialog, msg

  robot.respond /dialog/i, (msg) ->
    msg.send "listen dialog"

    dialog = new Dialog msg, (msg) ->
      text = msg.envelope.message.text
      if /Bye/i.test text
        @.end()
        msg.send "Bye"
        return
      else if text.match /I'm a (.+)/i
        @.set "name", RegExp.$1

      name = @.get("name") or "you"
      msg.send "#{name}: #{msg.envelope.message.text}"

    #Dialog.addDialog dialog
    Dialog.listen robot
