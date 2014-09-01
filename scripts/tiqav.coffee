# Description:
#   Get sensitive image from tiqav.com
#
# Commands:
#   hubot tiqav me <query>
#   hubot <query>の画像くれ
#   hubot 何か画像くれ

tiqav = require "tiqav.js"

module.exports = (robot) ->

  robot.respond /tiqav( me)? (.*)/i, (msg) ->
    tiqavMe msg, msg.match[2], (url) ->
      msg.send url

  robot.respond /(.+)の画像くれ/i, (msg) ->
    tiqavMe msg, msg.match[1], (url) ->
      msg.send url

  robot.hear /(ちくわ)/i, (msg) ->
    tiqavMe msg, msg.match[1], (url) ->
      msg.send url

  robot.respond /(何|なに|なん)か画像くれ/i, (msg) ->
    tiqavRandomMe msg, (url) ->
      msg.send url

tiqavMe = (msg, query, callback) ->
  tiqav.search.search query, (err, data)->
    return if err?

    index = parseInt Math.random() * data.length, 10
    url = tiqav.createImageUrl data[index].id, data[index].ext
    callback url

tiqavRandomMe = (msg, callback) ->
  tiqav.search.random (err, data) ->
    return if err?

    index = parseInt Math.random() * data.length, 10
    url = tiqav.createImageUrl data[index].id, data[index].ext
    callback url
