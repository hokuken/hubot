# Description:
#   Provide dialogues on hubot

util = require "util"
Path = require "path"

module.exports = (robot) ->

  # Dialogue class for hubot
  #
  # dialogue = new Dialogue user, callback # set username and room
  # dialogue.set key, value # set data to robot.brain.data.dialogues[username/room]
  # dialogue.end # end dialogue and destroy data
  #
  # Dialogue.get user
  # Dialogue.add dialogue
  # Dialogue.delete user or dialogue
  class Dialogue

    @dialogues = {}

    @listened = false

    @getKey: (user) ->
      "#{user.name}/#{user.room}"

    @get: (user) ->
      Dialogue.dialogues[Dialogue.getKey user.name, user.room]

    @add: (dialogue) ->
      Dialogue.dialogues[dialogue.key] = dialogue

    @delete: (user) ->
      if user instanceof Dialogue
        key = user.key
      else
        key = Dialogue.getKey user.name, user.room
      delete Dialogue.dialogues[key]

    @listen: util.deprecate((->), "Dialogue.listen is deprecated.")

    constructor: (user, callback) ->
      @username = user.name
      @room = user.room
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
      Dialogue.delete @
      robot.brain.data.dialogues?[@key] = null
      delete robot.brain.data.dialogues?[@key]
      @username = @room = @data = @callback = @callback = null

  # extend robot.receive
  org_receive = robot.receive
  robot.receive = (message) ->
    dialogue = Dialogue.get message.user
    dialogue?.callback.call dialogue, message

    org_receive.bind(robot)(message)

  # backword compatibility
  robot.brain.on "loaded", ->
    if robot.brain.data.dialogs?
      robot.brain.data.dialogues = robot.brain.data.dialogs
      delete robot.brain.data.dialogs
    robot.brain.data.dialogues = robot.brain.data.dialogues or {}

  robot.on "dialogue:start", (user, callback) ->
    new Dialogue user, callback

  robot.on "dialogue:set", (user, key, value) ->
    dialogue = Dialogue.get user
    dialogue?.set key, value
