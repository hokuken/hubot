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

module.exports = (robot) ->

  return unless process.env.PEATIX_CRAWLER_API_TOKEN and
     process.env.PEATIX_CRAWLER_URL

  class PeatixEvent

    @find: (id, callback) ->
      peatix_crawler_url = process.env.PEATIX_CRAWLER_URL
      peatix_crawler_token = process.env.PEATIX_CRAWLER_API_TOKEN
      url = "#{peatix_crawler_url}/api/events/" + id +
        "?token=#{peatix_crawler_token}"
      request url, callback

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
        robot.emit "dialogue:start", msg.envelope.user, (message) ->
          text = message.text
          if /(\d+)/i.test text
            index = parseInt(RegExp.$1, 10)-1
            if events[index]
              event = events[index]
              @respond event.toString()
            setTimeout =>
              @respond "他には？\n" +
                eventsToString(events) + "\n" +
                "何番のイベントの詳細を見ますか？[番号/見ない]"
            , 3000
          else if /^((見)?ない|(終|お)わり|おしまい)$/i.test text
            @respond "またご利用ください。"
            @end
      else
        msg.send "失敗しました。"

  robot.respond /イベントフォロー/i, (msg) ->
    msg.send "イベント情報を問い合わせ中です。。。"
    peatix_crawler_url = process.env.PEATIX_CRAWLER_URL
    peatix_crawler_token = process.env.PEATIX_CRAWLER_API_TOKEN
    url = "#{peatix_crawler_url}/api/passages" +
      "?token=#{peatix_crawler_token}"
    request url, (err, res, body) ->
      if !err and res.statusCode is 200
        should_follow_cnt = 0
        passages = JSON.parse body
        _.each(passages, (p) ->
          switch p.passage
            when 6
              should_follow_cnt++
              PeatixEvent.find p.event, (err, res, body) ->
                if !err and res.statusCode is 200
                  event = new PeatixEvent JSON.parse body
                  msg.send "開催から6日経過したイベントがあります。" +
                    "そろそろフォローメールを準備しては？\n" +
                    event.toString()
            when 29
              should_follow_cnt++
              PeatixEvent.find p.event, (err, res, body) ->
                if !err and res.statusCode is 200
                  event = new PeatixEvent JSON.parse body
                  msg.send "開催から約1ヶ月経過したイベントがあります。" +
                    "フィードバックもらいます？\n" +
                    event.toString()
        )

        unless should_follow_cnt > 0
          msg.send "本日フォローが必要なイベントは1件もありませんでした。"
