# Description:
#   Document Circular Feature
#
# Commands:
#   hubot circular:add - Add circular. *alias* : `hubot 回覧板を回して`
#   hubot circular:read - Inform hubot that you have read a circular. *alias* : `hubot 回覧板を読んだ`
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
      "こりゃ必読だがや、おみゃーさん、はよ読んでおいてちょーよ！"
      "Please read this circular in a few spare minutes."
    ]
    inform_read: [
      "私が確認するより先に読んだらチャンネルの方で `#{robot.name} 回覧板読んだ` と報告くださってもOKです。"
      "ちゃっと読んだら `#{robot.name} 回覧板読んだがや〜` って行ってちょーだぁ！ここじゃあかんよー。"
      "Please send me `#{robot.name} circular:read` when you read."
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
      "ホントに読んだんだ。。。もう、お別れダネ。。私のこと、忘れないでねッ （未練を残しつつも走り去る乙女）"
    ]
    come_again: [
      "では後ほど声かけますね！"
      "ラピュタは滅びんよ、何度でもよみがえるさ"
      "I'll be back"
    ]
    response_usage: [
      "回覧板の詳細をDMに送っていますよ！\n・・・で、読みました？ [yes/no]"
      "後で読むなら `後で` とお応えくださいね〜"
      ":heart: slackbot って書いてあるところ、通知ありません？\n確認済みなら `yes` ください :smile:"
      "yes/no でお答えください！"
      "I can accept only yes/no"
    ]
    bye: [
      "私たちにさよならなんて必要ありませんよね。"
      "See you again :heart:"
      "またご利用ください :hatching_chick:"
    ]
    invalid_number_provided: [
      "該当する回覧板はありません。"
      "すみません、提示した中から選んでください。"
      "あなた様の目は節穴でございますか？？"
    ]
    nothing_to_read: [
      "もう回覧板ないですよ。"
      "えーっと、回覧板は全部お読みのようです。。"
      "You have read all circulars."
    ]
    pick: (context) ->
      msgs = @[context] or []
      return "" if msgs.length is 0

      index = parseInt Math.random() * msgs.length, 10
      return msgs[index]


  class Circular

    # circulation interval - default: 30 min
    @interval = 1800000 #2000

    # wait time of each dialogue - default: 5sec
    @wait = 5000 #2000

    # wait time for respond to the dialogue - default: 5min
    @listen = 300000 #5000

    # circulation active duration - default: 2 days
    # TODO: consider duration
    @duration = 172800000

    @circulation = 0

    @onDialogue = false

    @circulars = []

    # Load a Circular instance from saved data
    @load: (data) ->
      Circular.circulars[data.id-1] or new Circular data

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
      @users = options.users or []
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

      Circular.circulars[@id-1] = @

    export: ->
      {
        id: @id
        user: @user
        room: @user
        users: @users
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
      users = @users.length and @users or Circular.users()
      @unread = _.without users, @user
      @queue = @unread.slice 0

    # Start circular dialogues
    run: ->
      @save()

      if @unread.length > 0 and @unread.length is @queue.length
        @notify()

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

    readBy: (user) ->
      if user in @unread
        @unread = _(@unread).without user
        @queue = _(@queue).without user
        @read.push user
        @save()
        if @unread.length is 0
          @complete()
        robot.emit "circular:read", @

    # send DM to specified users
    notify: ->
      target = "<!everyone>"
      users = Circular.users()
      users = @users if @users.length
      text = "@#{@user} から回覧板が届いています。\n\n" +
        @toString() + "\n\n" +
        messages.pick("ask_read") + "\n" +
        messages.pick("inform_read")
      for u in users
        robot.send {room: "@#{u}"}, text

    # Request reading of circular
    requestRead: (user, callback) ->
      # dialogue start
      self = @

      if Circular.onDialogue
        callback.call()
        return

      Circular.onDialogue = true
      @send "@#{user} さん、" + messages.pick("greet") + "\n" +
        "回覧板 No.#{@id} *#{@title}* は読まれましたか？ [yes/no]"

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

    # load circulars
    for data in robot.brain.data.circular.backNumbers
      circular = Circular.load(data)
      circular.run() unless circular.isCompleted()

  # ---- response ----

  addCircular = (msg) ->
    msg.send messages.pick("new")

    # Dialogue start
    robot.emit "dialogue:start", msg.envelope.user, (message) ->

      done_create = =>
        circular = new Circular @get "circular"
        circular.run()
        msg.send messages.pick("done_create")
        @end()

      text = "#{message.text}"

      circular = @get "circular"

      if ! circular
        options =
          user: message.user.name
          room: message.user.room
          content: message.text

        @set "circular", options
        msg.send "オプション設定をしますか？ [yes/no]"
        @set "phase", "options:start:confirm"
      else
        switch @get "phase"
          when "options:start:confirm"
            if /yes|はい|する/i.test text
              msg.send "対象ユーザーは誰ですか？ [all/user1 user2 ...]"
              @set "phase", "options:users"
            else
              @set "phase", "options:end"
              done_create()
          when "options:users"
            if /^all|全員$/i.test text
              msg.send "全員ですね"
              @set "phase", "options:end"
              done_create()
            else
              tokens = text.split /\s+/
              circular.users = _.map tokens, (token) ->
                token.replace /@/g, ""
              circular.users = _.intersection Circular.users(), circular.users
              if circular.users.length
                msg.send "#{circular.users.join ', '} の #{circular.users.length} 人ですね。"
                @set "circular", circular
                @set "phase", "options:end"
                done_create()
              else
                msg.send "やだなぁ、有効なユーザー名じゃないですよ。"

  readCircular = (msg) ->
    dialogue_with = user = msg.envelope.user.name
    user = "user1" if DEBUG
    circulars = robot.brain.data.circular.backNumbers
    circulars = _(circulars).filter (circular) ->
      !circular.completed_at and user in circular.unread
    if circulars.length is 1
      circular = Circular.load circulars.pop()
      circular.readBy user
      msg.send "回覧板 No.#{circular.id} *#{circular.title}* を読まれたのですね！\n" +
        messages.pick("thank")
    else if circulars.length > 1
      msg.send "どの回覧版ですか？"
      text = ""
      for circular in circulars
        text += "#{circular.id} : *#{circular.title}*\n"
      msg.send text
      robot.emit "dialogue:start", {name: dialogue_with, room: msg.envelope.user.room}, (message) ->
        text = message.text
        if text.match /^(\d+)$/i
          cid = parseInt(RegExp.$1, 10)
          circular = _(circulars).find (circular) ->
            circular.id is cid
          circular = Circular.load circular
          circular.readBy user
          msg.send "回覧板 No.#{circular.id} *#{circular.title}* を読まれたのですね！\n" +
            messages.pick("thank")
        else
          msg.send messages.pick "invalid_number_provided"
        @end
    else
      msg.send messages.pick "nothing_to_read"

  robot.respond /circular:add/i, addCircular
  robot.respond /回覧板(を|、)?回/i, addCircular

  robot.respond /circular:read/i, readCircular
  robot.respond /回覧板(を|、)?読/i, readCircular

  robot.respond /circular:clear/i, (msg) ->
    robot.brain.data.circular = {backNumbers: []}
