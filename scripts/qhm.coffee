# Description:
#   Utility for QHM
#
# Configuration:
#   ENSMALL_HOOK_URL - webhook on ensmall.net
#   ENSMALL_TOKEN - Secret token of ensmall webhook
#
# Commands:
#   hubot qhm:enc <text> - encode string to hex
#   hubot qhm:dec <hex> - decode hex to string
#   hubot qhm:set <url> - set QHM site url
#   hubot qhm:edit <pagename|url> - get edit-page URL
#   hubot qhm:release - Release latest QHM

Path = require "path"
URL = require "url"
conv = require "binstring"
request = require "request"
crypto = require "crypto"

module.exports = (robot) ->

  stringToHex = (msg) ->
    string = msg.match[1]
    hex = conv string, {in: "utf8", out: "hex"}
    msg.send hex.toUpperCase()

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

  release_messages = [
    "QHM、リリースできました！"
    "エンスモーくんが一晩でやってくれました！"
    "フフフ、このリリースが終わったら私、結婚するんですよ :heart:"
    "リリース完了！田舎の母さんに桃でも送ってやんなよ！"
    "ダルビッシュに投手交代！おっとこれはリリーフでした！"
  ]

  releaseQHM = (msg) ->
    return msg.send "利用できません" unless process.env.ENSMALL_HOOK_URL and process.env.ENSMALL_TOKEN
    return msg.send "#dev でお願いします" unless msg.envelope.user.room in ["dev", "Shell"]

    url = process.env.ENSMALL_HOOK_URL + "/release"
    data =
      repository: {name: "qhmpro"}
    pkg = require Path.join __dirname, '..', 'package.json'
    version = pkg.version

    text = JSON.stringify data
    key = process.env.ENSMALL_TOKEN
    sha1 = crypto.createHmac('sha1', key)
      .update(text).digest('hex')
    signature = "sha1=#{sha1}"

    request
      url: url
      method: "POST"
      headers:
        "User-Agent": "Hokuken-Hubot/#{version}"
        "X-Hub-Signature": signature
      json: data
    , (err, res, body) ->
      if err or res.statusCode is not 200
        msg.send "リリースできませんでした :goberserk:"
      else
        msg.send msg.random release_messages


  robot.respond /qhm:enc (.+)$/i, stringToHex

  robot.respond /qhm:dec (.+)$/i, hexToString

  robot.respond /qhm:set (https?:\/\/.+)/i, setBaseUrl

  robot.respond /qhm:edit(?: (.+))?/i, editPage

  robot.respond /qhm:release/i, releaseQHM
  robot.respond /qhm\s*を?リリース/i, releaseQHM

  robot.brain.on "loaded", ->
    robot.brain.data.qhm = robot.brain.data.qhm or {}
