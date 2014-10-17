# Description:
#   Document Circular Feature
#
# Commands:
#   hubot circular:add - Add circular. *alias* : `hubot 回覧板を回して`
#   hubot circular:clear - Clear all data for debug

moment  = require "moment"
_       = require "underscore"
cheerio = require "cheerio"
request = require "request"

module.exports = (robot) ->

  DEBUG = robot.adapterName is "shell"

  messages =
    new: [
      "新しい回覧板を作成します。内容、あるいは内容が記載されているURLを教えてください。"
      "こんにちは！回覧板ですねー。内容を一度にお願いします。URLでもOKです。"
      "Hi, I'll create a new circular. Please tell me a message or URL."
    ]
    done_create: [
      "回覧板を作成しました。閲覧状況は都度お知らせしますね。"
      "確かに受け付けました。皆さんに回しておきますー！"
      "Done. I'll ask everyone to read this circular."
    ]
    ask_read: [
      "早速お読みください！読んだかどうか、後で確認しますね。"
      "こりゃ必読だがや、みんな読んでおいてちょーでゃー！"
      "Please read this circular in a few spare minutes."
    ]
    greet: [
      "お忙しいところ失礼します。"
      "邪魔するでぇ〜"
      "ごきげんよう"
      "How's it going?"
    ]
    ignored: [
      "お返事がないので出直しますね。。"
      "また来るでぇ〜"
      "これが若さか。。。"
    ]
    thank: [
      "ありがとうございます。"
      "Thanks for reading!!"
      "読み終わっちゃったんだ。。。私のこと、忘れないでねッ （未練を残しつつも走り去る乙女）"
    ]
    come_again: [
      "では後ほど声かけますね！"
      "ラピュタは滅びんよ、何度でもよみがえるさ"
      "I'll be back"
    ]
    ask_again: [
      "以上。読んだら「読んだ」って行ってくださいね。後で読むなら「待って」と。"
      ":point_up: 面白かった？ [はい/いいえ]"
      "Did you read yet? [yes/no]"
    ]
    response_usage: [
      "yes/no/what でお答えください！"
      "I can accept only yes/no/what"
      "返事はこう！「はい」「いいえ」「何ですか？」！"
    ]
    bye: [
      "私たちにさよならなんて必要ありませんよね。"
      "See you again :heart:"
      "またご利用ください :hatching_chick:"
    ]
    pick: (context) ->
      msgs = @[context] or []
      return "" if msgs.length is 0

      index = parseInt Math.random() * msgs.length, 10
      return msgs[index]


  class Circular

    # circulation interval - default: 15 min
    @interval = 900000 #2000

    # wait time of each dialogue - default: 5sec
    @wait = 5000 #2000

    # wait time for respond to the dialogue - default: 5min
    @listen = 300000 #5000

    # circulation active duration - default: 2 days
    # TODO: consider duration
    @duration = 172800000

    @circulation = 0

    @onDialogue = false

    # Load a Circular instance from saved data
    @load: (data) ->
      new Circular(data)

    @users: ->
      return ["user1", "user2", "user3"] if DEBUG
      users = []
      for id, user of robot.brain.users()
        users.push user.name
      users

    constructor: (options) ->
      @id = options.id or ++Circular.circulation

      @user = options.user
      @room = options.room
      @content = options.content

      @type = options.type or null
      @read = options.read or []
      @unread = options.unread or []
      @queue = options.queue or []
      @title = options.title or null
      @created_at = options.created_at or moment().format()
      @completed_at = options.completed_at or null
      @interval = options.interval or Circular.interval
      @wait = options.wait or Circular.wait
      @listen = options.listen or Circular.listen
      @duration = options.duration or Circular.duration

      users_total = @read.length + @unread.length + @queue.length
      @parseContent() if @type is null
      @setQueue() if users_total is 0

    export: ->
      {
        id: @id
        user: @user
        room: @user
        read: @read
        unread: @unread
        queue: @queue
        type: @type
        title: @title
        content: @content
        created_at: @created_at
        completed_at: @completed_at
        interval: @interval
        wait: @wait
        listen: @listen
        duration: @duration
      }

    save: ->
      robot.brain.data.circular.backNumbers[@id-1] = @export()

    parseContent: ->
      @content = @content.trim()
      # URL provided
      if /^https?:\/\//i.test @content
        @type = "url"
        # get title
        url = @content
        request url, (err, res, body) =>
          if !err and res.statusCode is 200
            $ = cheerio.load body
            @title = $("title").text()
      else
        @type = "text"
        @title = @content.split("\n")[0]
        @content = @content.split("\n").slice(1).join "\n"

    toString: ->
      str = "回覧板 No.#{@id} *#{@title}*\n"
      switch @type
        when "url"
          str += "#{@content}"
        when "text"
          if @content.length > 0
            str += "```\n" +
              "#{@content}\n" +
              "```"
          else
            str += "...本文はありません..."
      str

    setQueue: ->
      @unread = _.without Circular.users(), @user
      @queue = @unread.slice 0

    # Start circular dialogues
    run: ->
      @save()

      if @unread.length > 0 and @unread.length is @queue.length
        setTimeout =>
          @broadcast()
        , @wait * 2

      if @unread.length > 0 and @queue.length is 0
        @queue = @unread.slice 0

      # dequeue and dialogue
      setTimeout =>
        @dequeue()
      , @interval

    dequeue: ->
      return if @isCompleted()

      if @queue.length > 0
        user = @queue.shift()
        @save()
        @requestRead user, =>
          if @queue.length > 0
            setTimeout =>
              @dequeue()
            , @wait
          else if @unread.length > 0
            @queue = @unread.slice 0
            setTimeout =>
              @dequeue()
            , @interval
          else
            @complete()

    broadcast: ->
      text = "@everyone @#{@user} からのお知らせがあります。\n" +
        @toString() + "\n" +
        messages.pick("ask_read")
      @send text

    # Request reading of circular
    requestRead: (user, callback) ->
      # dialogue start
      self = @

      if Circular.onDialogue
        console.log "skip dialogue"
        callback.call()
        return

      Circular.onDialogue = true
      @send "@#{user} さん、" + messages.pick("greet") + "\n" +
        "回覧板 No.#{@id} *#{@title}* は読まれましたか？ [yes/no/what]\n"

      # timeout for non-response from user
      timeout_id = setTimeout =>
        @send messages.pick("ignored")
        @breakRequest(user)
        callback.call()
        Circular.onDialogue = false
      , @listen

      dialogue_with = user
      dialogue_with = "Shell" if DEBUG

      robot.emit "dialogue:start", {name: dialogue_with, room: @room}, (message)->
        clearTimeout timeout_id
        text = message.text
        if /yes|OK|read|done|はい|読んだ|読みました|オッケー/i.test text
          response = messages.pick("thank")
          self.unread = _.without self.unread, user
          self.read.push user
          self.save()
          callback.call()
          robot.emit "circular:read", self
          @end()
          Circular.onDialogue = false
        else if /no|NG|not read|unread|yet|いいえ|まだ|読んでない|待って/i.test text
          response = messages.pick("come_again")
          callback.call()
          @end()
          Circular.onDialogue = false
        else if /what|\?|？|何/i.test text
          response = "回覧板の内容はこちらです。\n" + self.toString() + "\n\n" +
            messages.pick("ask_again")
        else
          response = messages.pick("response_usage")

        robot.send {room: message.user.room}, response

    breakRequest: (user) ->
      dialogue_with = user
      dialogue_with = "Shell" if DEBUG
      robot.emit "dialogue:break", {name: dialogue_with, room: @room}

    # Send to room adapt to slack
    send: (message) ->
      path = "/services/hooks/hubot"
      data =
        text:     message
        username: @user
        channel:  @room
        mrkdwn:   true

      if robot.adapter.post
        robot.adapter.post? path, JSON.stringify data
      else
        robot.send {room: @room}, message


    # Send report to writer
    report: ->
      text = ""
      if @unread.length > 0
        text = "回覧板 No.#{@id} *#{@title}* の閲覧状況を報告します。\n" +
          "現在 #{@read.length} 人が閲覧済みです。\n" +
          "未読ユーザーは #{@unread.join ', '} の #{@unread.length} 人です。"
      else
        seconds = moment(@completed_at).diff(moment(@created_at), 'seconds')
        minutes = moment(@completed_at).diff(moment(@created_at), 'minutes')
        hours = moment(@completed_at).diff(moment(@created_at), 'hours')

        if minutes is 0
          duration = "#{seconds} 秒"
        else if hours is 0
          duration = "#{minutes} 分"
        else
          duration = "#{hours} 時間"

        text = "回覧板 No.#{@id} *#{@title}* を全員が閲覧したようです。\n" +
          "所要時間は #{duration}でした。\n" +
          messages.pick("bye")
      robot.send {room: "@#{@user}"}, text

    complete: ->
      @completed_at = moment().format()
      @save()
      robot.emit "circular:complete", @

    isCompleted: ->
      !!@completed_at

  robot.on "circular:read", (circular) ->
    circular.report()
  robot.on "circular:complete", (circular) ->
    console.log "complete circular: #{circular.id}"

  robot.brain.on "loaded", ->
    robot.brain.data.circular = robot.brain.data.circular or {backNumbers: []}
    robot.brain.data.circular.backNumbers = robot.brain.data.circular.backNumbers or []
    Circular.circulation = robot.brain.data.circular.backNumbers.length
    console.log "Circular last id : #{Circular.circulation}"

    # load circulars
    for data in robot.brain.data.circular.backNumbers
      circular = Circular.load(data)
      circular.run() unless circular.isCompleted()

  # ---- response ----

  addCircular = (msg) ->
    msg.send messages.pick("new")

    # Dialogue start
    robot.emit "dialogue:start", msg.envelope.user, (message) ->
      text = message.text
      options =
        user: message.user.name
        room: message.user.room
        content: message.text
      circular = new Circular options
      circular.run()

      msg.send messages.pick("done_create")

      @end()

  robot.respond /circular:add/i, addCircular
  robot.respond /回覧板を?回して/i, addCircular

  robot.respond /circular:clear/i, (msg) ->
    robot.brain.data.circular = {backNumbers: []}
