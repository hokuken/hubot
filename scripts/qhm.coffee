# Description:
#   Utility for QHM
#
# Commands:
#   hubot qhm:enc <text> - encode string to hex
#   hubot qhm:dec <hex> - decode hex to string
#   hubot qhm:set <url> - set QHM site url
#   hubot qhm:edit <pagename|url> - get edit-page URL

URL = require "url"
conv = require "binstring"

module.exports = (robot) ->

  stringToHex = (msg) ->
    string = msg.match[1]
    hex = conv string, {in: "utf8", out: "hex"}
    msg.send hex

  hexToString = (msg) ->
    username = msg.envelope.user.name
    hex = msg.match[1]
    string = conv hex, {in: "hex", out: "utf8"}
    msg.send string

    if robot.brain.data.qhm[username]?.url
      urldata = URL.parse robot.brain.data.qhm[username].url
      urldata.search = encodeURIComponent string
      page_url = URL.format urldata
      msg.send "#{page_url}"

  setBaseUrl = (msg) ->
    url = msg.match[1].trim()
    urldata = URL.parse url
    urldata.search = ""
    url = URL.format url
    username = msg.envelope.user.name
    robot.brain.data.qhm[username] = {url}
    msg.send "QHMのURLを設定しました :metal:\n" +
      url

  getBaseUrl = (msg) ->
    username = msg.envelope.user.name
    robot.brain.data.qhm[username]?.url or ""

  editPage = (msg) ->
    pagename = msg.match[1]?.trim()
    baseurl = getBaseUrl msg
    if pagename and /^https?:\/\//i.test pagename
      urldata = URL.parse pagename
      pagename = urldata.search?.substr(1) or ""
      urldata.search = ""
      baseurl = URL.format urldata

    if pagename
      urldata = URL.parse baseurl
      urldata.query = {cmd: "edit", page: pagename}
    else
      urldata = URL.parse baseurl
      urldata.query = {cmd: "qhmauth"}
    edit_url = URL.format urldata
    msg.send edit_url


  robot.respond /qhm:enc (.+)$/i, stringToHex

  robot.respond /qhm:dec (.+)$/i, hexToString

  robot.respond /qhm:set (https?:\/\/.+)/i, setBaseUrl

  robot.respond /qhm:edit(?: (.+))?/i, editPage

  robot.brain.on "loaded", ->
    robot.brain.data.qhm = robot.brain.data.qhm or {}
