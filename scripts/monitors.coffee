# Description:
#   サービスの稼働状況を監視する
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot <URL>を監視して
#   hubot 今の稼働状況を教えて
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

  class Monitor
    @schema = {
      url: null
      status: null
      statusCode: null
      downedAt: null
      checkedAt: null
    }

    @adjustUrl: (url) ->
      url = _s.trim url
      unless /^https?:\/\//i.test url
        url = "http://" + _s.ltrim url, "/"
      url

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
      buffer = "#{@url}: *#{@data.status}* (";
      buffer += "status code: #{@data.statusCode}, " if @data.statusCode
      buffer += "updated at: #{@data.checkedAt}"
      buffer += ", downed at: #{@data.downedAt} " if @data.downedAt
      buffer += ")"

  robot.respond /(.+)を監視(?:して)?/i, (msg) ->
    url = Monitor.adjustUrl msg.match[1]
    #registerMonitor service
    urlinfo = URL.parse url
    msg.send "#{urlinfo.hostname}の監視を開始しました"
    monitor = new Monitor url
    monitor.save()
    monitor.run (err) ->
      if err
        if monitor.data.status == "missing"
          msg.send "#{monitor.url} へアクセスできません。"
        else
          msg.send "#{monitor.url} でエラーが起きています" +
            "（ステータス：#{monitor.data.statusCode}）"
      else
        msg.send "#{monitor.url} は正常に動作しています。"

  robot.respond /.*稼働状況.*/i, (msg) ->
    #getMonitor
    msg.send "現在の稼働状況は..."
