# Description:
#   github の API をたたく
#
# Commands:
#   hubot github emoji yum #-> https://assets-cdn.github.com/images/icons/emoji/yum.png?v5

fs = require "fs"

cachefile = "cache/github-emojis.json"

module.exports = (robot) ->
  robot.respond /(?:github )?emoji(?: me)? (.*)/i, (msg) ->
    emojiMe msg, (url) ->
      msg.send url

  robot.respond /github clean/i, (msg) ->
    clearEmojiCache msg

emojiMe = (msg, cb) ->
  emoji_arr = msg.match[1]
    .replace(/^[ ]*/, "").replace(/[ ]*$/, "")
    .split(/\s+/)
  if fs.existsSync(cachefile)
    body = fs.readFile cachefile, (err, data) ->
      emojis = JSON.parse(data)
      for emoji in emoji_arr
        emoji_url = emojis[emoji]
        cb emoji_url || "ないよ"

  else
    msg.http('https://api.github.com/emojis')
      .get() (err, res, body) ->
        fs.writeFile cachefile, body
        emojis = JSON.parse(body)
        for emoji in emoji_arr
          emoji_url = emojis[emoji]
          cb emoji_url || "ないよ"


clearEmojiCache = (msg) ->
  fs.unlinkSync cachefile
  msg.send "Clear GitHub emoji cache!"
