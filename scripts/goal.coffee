# Description:
#   Set the goal of today
#
# Commands:
#   hubot 今日の目標は〜 - 今日の目標を設定します。期限は同日午前3時です。
#   hubot 今日の目標は？ - 今日の目標を表示します。
#   hubot 目標達成 - 目標を達成したことを hubot に知らせます。
#   hubot 達成度 - 目標の達成度を hubot に聞きます。

moment = require "moment"
_ = require "underscore"
Path = require "path"
Dialog = require Path.join __dirname, "..", "src", "dialog"


module.exports = (robot) ->

  robot.brain.data.goals = {} unless robot.brain.data.goals?

  congraturations = [
    "目標達成おめでとうございます！"
    "わお！素晴らしいですね！！"
    "私は達成できると信じていました。明日も頑張りましょう！"
    "Awesome!! Have a nice day!"
  ]

  reviews = [
    "うーん、もう少し、踏ん張りましょう。。 :triumph:" #<20
    "大丈夫、決して低くないですよ！ :bullettrain_side:" #<40
    "達成道は長く険しい道です。明日も一歩踏み出しましょう！ :turtle:" #<60
    "お見事！このまま目標達成し続けてくださいね！ :ok_woman:" #<80
    "信じられない！あなたもしかして、Achieverですか？ :heart_eyes:" #<100
    "あ、あなたが神か。。 :innocent:" #=100
  ]

  colors = [
    "1abc9c"
    "2ecc71"
    "3498db"
    "9b59b6"
    "e67e22"
    "e74c3c"
  ]

  robot.respond /目標設定/i, (msg) ->
    dialog = new Dialog msg, (msg) ->
      text = msg.envelope.message.text
      if text.length is 0 or /^(help|ヘルプ|わからん)$/i.test text
        msg.send "何かおっしゃってください。目標として設定します。" +
          "「もうない」や「終わり」と言えば目標設定モードを終了します。"
      else if /^((もう)?ない|(終|お)わり|おしまい)$/i.test text
        msg.send "ありがとうございました。現在設定中の目標は\n" +
          (_.map @.get("goals"), (goal, i) ->
            "#{i+1} : #{goal}"
          ).join "\n"
        @.end()
      else
        goals = @.get("goals") or []
        goals.push text
        @.set "goals", goals
        msg.send "「#{text}」を目標として設定しました。" +
          "もうなければ、「ない」とか「終わり」とか言ってくださいね。"

    goals = dialog.get("goals") or []
    dialog.set "goals", goals
    msg.send "#{msg.envelope.user.name}さんの目標を教えてください！\n" +
      "なければ、「ない」とか「終わり」とか言ってくださいね。"

    #Dialog.addDialog dialog
    Dialog.listen robot

  robot.respond /今日の目標は(?!？)([\s\S]+)/i, (msg) ->
    goal = msg.match[1]
    user = msg.envelope.user.name
    expiration = moment()
      .set("date", moment().get("date") + 1)
      .startOf("day").set("hour", 3)

    unless robot.brain.data.goals[user]?
      robot.brain.data.goals[user] = {
        attempted: 0
        achieved: 0
      }
    _.extend robot.brain.data.goals[user], {
      expiration: expiration.format()
      goal: goal
      attempted: robot.brain.data.goals[user].attempted + 1
    }

    msg.send "OK。#{user}さんの今日の目標は「#{goal}」ですね。"

  robot.respond /今日の目標は(？)?$/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null

    unless data and moment(data.expiration).isAfter moment()
      msg.send "#{user}さんの今日の目標は設定されておりません。"
      return
    msg.send "#{user}さんの今日の目標は「#{data.goal}」です。"

  robot.respond /.*目標達成.*/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null

    unless data and moment(data.expiration).isAfter moment()
      msg.send "#{user}さん、今日は目標設定してないですよ。"
      return
    robot.brain.data.goals[user].achieved += 1
    robot.brain.data.goals[user].expiration = moment().format()
    msg.send "#{user}さんの目標は。。。\n「#{data.goal}」ですね。\n" +
      msg.random congraturations

  robot.respond /.*達成度.*/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null
    embed_user = user

    unless data and data.attempted
      embed_user = null
      msg.send "#{user}さんのデータはありませんが。。"

    user_goals_data = robot.brain.data.goals

    user_rates = {}
    for _user, _data of user_goals_data
      attempted = _data.attempted
      achieved = _data.achieved
      rate = getRate achieved, attempted
      user_rates[_user] = rate

    chart_url = getBarCharUrl user_rates, embed_user
    url_shorten chart_url, (chart_url) ->
      unless data and data.attempted
        msg.send "皆さんの目標達成度のチャートです。\n" +
          chart_url
      else
        rate = getRate data.achieved, data.attempted
        review = reviews[Math.floor rate / 20]
        msg.send "#{user}さんの目標達成度は、" +
          "#{rate}%" +
          "（#{data.achieved} / #{data.attempted}）です！\n" +
          review + "\n" +
          chart_url



  getRate = (achieved, attempted) ->
    Math.round achieved / attempted * 100

  getBarCharUrl = (user_rates, embed_user) ->
    Quiche = require "quiche"
    bar = new Quiche "bar"
    bar.setWidth 400
    bar.setHeight 50 + 20 * _.keys(user_rates).length
    bar.setTitle "目標達成度"
    bar.setBarHorizontal()
    bar.setBarWidth 10
    bar.setBarSpacing 5
    bar.setLegendLeft()

    if embed_user?
      index = parseInt Math.random() * colors.length, 10
      embed_color = colors[index]

    for user, rate of user_rates
      if embed_user?
        if user is embed_user
          color = embed_color
        else
          color = "95a5a6"
      else
        index = parseInt Math.random() * colors.length, 10
        color = colors[index]
      bar.addData [rate], user, color

    bar.addData [100], "神", "95a5a6"

    bar.addAxisLabels('x', [0, 25, 50, 75, 100])

    bar.getUrl true

  url_shorten = (url, callback) ->
    request = require "request"

    options = {
      uri: "https://www.googleapis.com/urlshortener/v1/url"
      json: {longUrl: url}
      method: "POST"
    }

    res = request options, (e, r, body) ->
      data = body
      callback data.id if data.id?
