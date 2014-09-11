# Description:
#   Set the goal of today
#
# Commands:
#   hubot 今日の目標は〜 - 今日の目標を設定します。期限は同日午前3時です。
#   hubot 今日の目標は？ - 今日の目標を表示します。
#   hubot 目標達成 - 目標を達成したことを hubot に知らせます。


Util = require "util"
moment = require "moment"
_ = require "underscore"

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

  robot.respond /今日の目標は(?!？)(.+)/i, (msg) ->
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
      expiration: expiration
      goal: goal
      attempted: robot.brain.data.goals[user].attempted + 1
    }

    msg.send "OK。#{user}さんの今日の目標は「#{goal}」ですね。"

  robot.respond /今日の目標は？/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null

    unless data and data.expiration.isAfter moment()
      msg.send "#{user}さんの今日の目標は設定されておりません。"
      return
    msg.send "#{user}さんの今日の目標は「#{data.goal}」です。"

  robot.respond /.*目標達成.*/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null

    unless data and data.expiration.isAfter moment()
      msg.send "#{user}さん、今日は目標設定してないですよ。"
      return
    robot.brain.data.goals[user].achieved += 1
    robot.brain.data.goals[user].expiration = moment()
    msg.send "#{user}さんの目標は。。。\n「#{data.goal}」ですね。\n" +
      msg.random congraturations

  robot.respond /.*達成度.*/i, (msg) ->
    user = msg.envelope.user.name
    data = robot.brain.data.goals[user] or null

    unless data and data.attempted
      msg.send "#{user}さんのデータはありません。"
      return

    attempted = data.attempted
    achieved = data.achieved
    rate = Math.round achieved / attempted * 100

    review = reviews[Math.floor rate / 20]

    msg.send "#{user}さんの目標達成度は、" +
      "#{rate}%（#{achieved} / #{attempted}）です！\n" +
      review
