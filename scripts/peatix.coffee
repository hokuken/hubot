# Description:
#   Peatix の情報を peatix-crawler へ問い合わせる
#
# Commands:
#   hubot イベント情報 - 対話モードでイベントの一覧や情報を呼び出す
#
# Configuration:
#   PEATIX_CRAWLER_URL - peatix-crawler の URL
#   PEATIX_CRAWLER_API_TOKEN - peatix-crawler の API キー

request = require 'request'
moment = require 'moment'
_ = require "underscore"
numeral = require "numeral"
Path = require "path"
Dialog = require Path.join __dirname, "..", "src", "dialog"

module.exports = (robot) ->

  return unless process.env.PEATIX_CRAWLER_API_TOKEN and
     process.env.PEATIX_CRAWLER_URL

  class PeatixEvent
    constructor: (data) ->
      @data = data

    past: ->
      moment(@data.datetime).isBefore moment()

    pastString: ->
      if @past
        "終了"
      else
        "未開催"

    income: ->
      income_total = 0
      _.each(@data.tickets, (t) =>
        income_total += @parse_income(t.subtotal_display)
      )
      income_total

    parse_income: (income_display) ->
      parseInt(income_display.replace(/¥|,/gi, ""), 10)

    incomeToString: ()->
      "¥" + numeral(@income()).format '0,0'

    toString: (short=false)->
      if short
        buffer =  "*#{@data.name}* "
        buffer += "（#{@pastString()}） "
        buffer += "#{@data.dashboard_uri}"
      else
        datetime = moment(@data.datetime).format("YYYY年M月D日")
        weekday = "日月火水木金土".split('')[moment(@data.datetime).day()]
        datetime += "（#{weekday}）"
        buffer =  "*#{@data.name}*\n"
        buffer += "開催日：#{datetime} （#{@pastString()}）\n"
        buffer += "チケット：#{@data.seats_sold} / #{@data.seats_total} \n"
        buffer += "売り上げ：#{@incomeToString()}\n"
        buffer += "管理画面：#{@data.dashboard_uri}\n"
        buffer += "#{@data.banner_thumbnail}"
      buffer

  eventsToString = (events) ->
    (_.map events, (event, i) ->
      "#{i+1} : #{event.toString true}"
    ).join "\n"

  robot.respond /イベント情報/i, (msg) ->

    msg.send "イベント情報を問い合せ中です。。。"
    peatix_crawler_url = process.env.PEATIX_CRAWLER_URL
    peatix_crawler_token = process.env.PEATIX_CRAWLER_API_TOKEN
    url = "#{peatix_crawler_url}/api/events" +
      "?token=#{peatix_crawler_token}"
    request url, (err, res, body) =>
      if !err and res.statusCode is 200
        events = JSON.parse body
        events = _.map(events, (e) ->
          new PeatixEvent e
        )
        msg.send "#{events.length}件のイベントが見つかりました。\n" +
          eventsToString(events) + "\n" +
          "何番のイベントの詳細を見ますか？[番号/見ない]"
        dialog = new Dialog msg, (msg) ->
          text = msg.envelope.message.text
          if /(\d+)/i.test text
            index = parseInt(RegExp.$1, 10)-1
            if events[index]
              event = events[index]
              msg.send event.toString()
            msg.send "他には？\n" +
              eventsToString(events) + "\n" +
              "何番のイベントの詳細を見ますか？[番号/見ない]"
          else if /^((見)?ない|(終|お)わり|おしまい)$/i.test text
            msg.send "またご利用ください。"
            @end
        Dialog.listen robot
      else
        msg.send "失敗しました。"
