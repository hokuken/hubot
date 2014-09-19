# Dialog class for hubot
#
# dialog = new Dialog msg, callback # set username and room
# dialog.set key, value # set data to robot.brain.data.dialogs[user/room]
# dialog.end # end dialog and destroy data
#
# Dialog.getDialog user, room
# Dialog.addDialog dialog
# Dialog.deleteDialog user, room

class Dialog

  @dialogs = {}

  @listened = false

  @getKey: (user, room) ->
    "#{user}/#{room}"

  @getDialog: (user, room) ->
    Dialog.dialogs[Dialog.getKey user, room]

  @addDialog: (dialog) ->
    Dialog.dialogs[Dialog.getKey dialog.user, dialog.room] = dialog

  @deleteDialog: (user, room) ->
    delete Dialog.dialogs[Dialog.getKey user, room]

  @listen: (robot) ->
    return false if Dialog.listened
    robot.hear /.*/i, (msg) ->
      dialog = Dialog.getDialog msg.envelope.user.name, msg.envelope.room
      dialog?.callback.call dialog, msg
    Dialog.listened = true

  constructor: (msg, callback) ->
    @robot = msg.robot
    @user = msg.envelope.user.name
    @room = msg.envelope.room
    @key = Dialog.getKey @user, @room
    @data = {}
    @listen callback
    Dialog.addDialog @

  set: (key, value) ->
    @data[key] = value
    @save()

  get: (key) ->
    @data[key]

  reset: ->
    @data = {}
    @save

  listen: (callback) ->
    @callback = callback
    @

  save: ()->
    @robot.brain.data.dialogs |= {}
    @robot.brain.data.dialogs?[@key] = @data
    @

  end: ->
    Dialog.deleteDialog @user, @room
    @robot.brain.data.dialogs?[@key] = null
    delete @robot.brain.data.dialogs?[@key]
    @user = @room = @data = @callback = @callback = null

module.exports = Dialog
