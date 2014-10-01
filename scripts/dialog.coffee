# Description:
#   Provide dialogues on hubot

util = require "util"
Path = require "path"

module.exports = (robot) ->

  # Dialogue class for hubot
  #
  # dialogue = new Dialogue msg, callback # set username and room
  # dialogue.set key, value # set data to robot.brain.data.dialogues[username/room]
  # dialogue.end # end dialogue and destroy data
  #
  # Dialogue.get username, room
  # Dialogue.add dialogue
  # Dialogue.delete username, room
  class Dialogue

    @dialogues = {}

    @listened = false

    @getKey: (username, room) ->
      "#{username}/#{room}"

    @get: (username, room) ->
      Dialogue.dialogues[Dialogue.getKey username, room]

    @add: (dialogue) ->
      Dialogue.dialogues[Dialogue.getKey dialogue.username, dialogue.room] = dialogue

    @delete: (username, room) ->
      delete Dialogue.dialogues[Dialogue.getKey username, room]

    @listen: util.deprecate((->), "Dialogue.listen is deprecated.")

    constructor: (username, room, callback) ->
      @username = username
      @room = room
      @key = Dialogue.getKey @username, @room
      @data = {}
      @listen callback
      Dialogue.add @

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

    respond: (strings...) ->
      robot.send {room: @room}, strings...

    save: ()->
      robot.brain.data.dialogues = robot.brain.data.dialogues or {}
      robot.brain.data.dialogues?[@key] = @data
      @

    end: ->
      Dialogue.delete @username, @room
      robot.brain.data.dialogues?[@key] = null
      delete robot.brain.data.dialogues?[@key]
      @username = @room = @data = @callback = @callback = null

  # extend robot.receive
  org_receive = robot.receive
  robot.receive = (message) ->
    username = message.user?.name
    room = message.user?.room
    dialogue = Dialogue.get username, room
    dialogue?.callback.call dialogue, message

    org_receive.bind(robot)(message)

  robot.respond /dialogue/i, (msg) ->
    user = msg.envelope.user.name
    room = msg.envelope.user.room

    robot.emit "dialogue:start", user, room, (message) ->
      robot.send {user: @user, room: @room}, "wahaha"
      @end()

  # backword compatibility
  robot.brain.on "loaded", ->
    if robot.brain.data.dialogs?
      robot.brain.data.dialogues = robot.brain.data.dialogs
      delete robot.brain.data.dialogs
    robot.brain.data.dialogues = robot.brain.data.dialogues or {}

  robot.on "dialogue:start", (username, room, callback) ->
    new Dialogue username, room, callback

  robot.on "dialogue:set", (msg, key, value) ->
    username = msg.envelope.user.name
    room = msg.envelope.room
    dialogue = Dialogue.get username, room
    dialogue?.set key, value
