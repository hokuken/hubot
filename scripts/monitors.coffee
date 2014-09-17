# Description:
#   サービスの稼働状況を監視する
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_MONITORS_CHANNEL: channel name for sending alert
#
# Commands:
#   hubot <URL>を監視
#   hubot 今の稼働状況は？
#
# URLS:
#   None

CronJob = require("cron").CronJob
_ = require 'underscore'
_s = require 'underscore.string'
moment = require 'moment'
request = require 'request'
URL = require 'url'

module.exports = (robot) ->

  robot.brain.data.monitors = {} unless robot.brain.data.monitors?

  room = process.env.HUBOT_MONITORS_CHANNEL

  class Monitor
    @schema = {
      url: null
      status: null
      statusCode: null
      downedAt: null
      checkedAt: null
      alertedAt: null
    }

    @adjustUrl: (url) ->
      url = _s.trim url
      unless /^https?:\/\//i.test url
        url = "http://" + _s.ltrim url, "/"
      url

    @addSchedule: (url) ->
      job = {
        cronTime: "*/1 * * * *"
        onTick: ->
          monitor = new Monitor url
          monitor.run (err) ->
            if err
              if monitor.data.alertedAt
                alerted_at = moment monitor.data.alertedAt
                if alerted_at.add(1, "h").isAfter moment()
                  return

              monitor.data.alertedAt = moment().format()
              monitor.save()
              if monitor.data.status is "missing"
                robot.send {room: room},
                  "#{monitor.url} へアクセスできません！" +
                  "至急確認してください @channel\n" +
                  monitor.toString()
              else
                robot.send {room: room},
                  "#{monitor.url} で問題が発生しています！" +
                  "至急確認してください @channel\n" +
                  monitor.toString()
        start: true
      }
      try
        new CronJob job
      catch error
        console.log error

    constructor: (url) ->
      @url = Monitor.adjustUrl url
      if robot.brain.data.monitors[@url]
        data = robot.brain.data.monitors[@url]
      else
        data = url: @url
      @data = _.extend {}, Monitor.schema, data

    save: () ->
      robot.brain.data.monitors[@url] = @data

    delete: () ->
      delete robot.brain.data.monitors[@url]

    run: (callback) ->
      request @url, (err, res, body) =>
        now = moment().format()
        if !err and res.statusCode is 200
          @data.checkedAt = now
          @data.downedAt = null
          @data.status = "alive"
          @data.statusCode = res.statusCode
          @save()
          callback? null
        else
          @data.downedAt = now unless @data.downedAt
          @data.checkedAt = now
          if res
            @data.status = "dead"
            @data.statusCode = res.statusCode
          else
            @data.status = "missing"
            @data.statusCode = null
          @save()
          callback? true

    toString: () ->
      buffer = "#{@url} : *#{@data.status}* (";
      buffer += "status code: #{@data.statusCode}, " if @data.statusCode
      buffer += "updated at: #{@data.checkedAt}"
      buffer += ", downed at: #{@data.downedAt} " if @data.downedAt
      buffer += ")"

  for url, monitor of robot.brain.data.monitors
    Monitor.addSchedule url

  robot.respond /(.+)を監視/i, (msg) ->
    url = Monitor.adjustUrl msg.match[1]
    #registerMonitor service
    urlinfo = URL.parse url
    msg.send "#{urlinfo.hostname}の監視を開始しました"
    monitor = new Monitor url
    monitor.save()
    monitor.run (err) ->
      if err
        if monitor.data.status is "missing"
          msg.send "#{monitor.url} へアクセスできません。監視を解除します"
          monitor.delete()
          return
        else
          msg.send "#{monitor.url} でエラーが起きています" +
            "（ステータス：#{monitor.data.statusCode}）"
      else
        msg.send "#{monitor.url} は正常に動作しています。"

      #register cron job
      Monitor.addSchedule monitor.url

  robot.respond /.*稼働状況.*/i, (msg) ->
    #getMonitor
    msg.send "現在の稼働状況は..."
    lines = []
    alive = 0
    dead = 0
    missing = 0
    for url, monitor of robot.brain.data.monitors
      m = new Monitor url
      switch m.data.status
        when "alive" then alive += 1
        when "dead" then dead += 1
        when "missing" then missing += 1
      lines.push m.toString()

    text = lines.join "\n"

    if dead + missing > 0
      text += "\n\n"
      text += "#{dead + missing}台のサーバーでエラーが発生しています。"

    setTimeout (-> msg.send text), 1000
