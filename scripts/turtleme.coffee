# Description:
#   hubotに亀の写真を拾ってきてもらう
#
# Commands:
#   hubot turtleme - Queries Google Images for turtle and returns a random top result.

# Hubotのスクリプトはモジュールとして記述し，
# Hubot起動時にrequireされてexportした関数が呼び出されます

module.exports = (robot) ->
  robot.respond /turtleme/i, (msg) ->
    turtleMe msg, (url) ->
      msg.send url



turtleMe = (msg, cb) ->
  q = v: '1.0', rsz: '8', q: 'turtle', safe: 'active', imgsz: 'medium|large'
  msg.http('http://ajax.googleapis.com/ajax/services/search/images')
    .query(q)
    .get() (err, res, body) ->
      images = JSON.parse(body)
      images = images.responseData?.results
      if images?.length > 0
        image = msg.random images
        cb "#{image.unescapedUrl}#.png"
