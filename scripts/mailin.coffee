# Description:
#   Mailin hooks
#
# Configuration:
#   HUBOT_TOKEN - hubot API Token
#
# Dependencies:
#   Slack Adapter - This script is for Slack
#   cloudmailin.com - This script has a route for mailin

cheerio = require "cheerio"
fs = require "fs"
request = require "request"

module.exports = (robot) ->

  robot.router.post "/hubot/mailhook", (req, res) ->
    query = req.query
    data = req.body
    unless process.env.HUBOT_TOKEN? and process.env.HUBOT_TOKEN in [query.token, body.token]
      res.writeHead 403
      res.end "NG"
      return

    messageId = data.headers['Message-ID']
    host = messageId.split(/@/)[1]

    switch host
      when "disqus.net"
        parser = new DisqusMailParser data
        # for Slack
        [message, data] = parser.createCustomMessage()
        robot.logger.info "Disqus mail parser catched"
        post message, data
      else
        res.writeHead 404
        res.end "Parser Not Found"
        return

    res.end "OK"

  post = (message, attachments...) ->
    robot.logger.info "Post to hubot hook via mailin script"

    path = "/services/hooks/hubot"
    data =
      username: robot.name
      channel: message.room
      attachments: attachments

    robot.adapter.post? path, JSON.stringify data

  class MailParser
    constructor: (data) ->
      @data = data
      @parse()

    subject: ->
      @data.headers?.Subject

    parse: ->

    # Create Data Object for Custom message of slack
    # @return [message, data]
    #   message: {room}
    #   data: {text, fallback, pretext, color, fields}
    createCustomMessage: ->


  class DisqusMailParser extends MailParser

    parse: ->
      html = @data.html
      $ = cheerio.load html
      parser = @

      # Get the Disqus shortname and the link to page
      $("h3").first().children("a").each ->
        parser.shortname = $(this).text()
        parser.url = $(this).attr "href"

      # Get the user data
      $("a > img[title$=profile]").each ->
        title = $(this).attr "title"
        username = title.match(/^Visit (.+)'s profile/i)[1]
        parser.user = {
          name: username
          avatar: $(this).attr "src"
          profile: $(this).parent().attr "href"
        }

      # Get the post content
      $("h4").first().next("p").each ->
        $contents = $(this).nextUntil("table")
        parser.datetime = $contents.last().text()
        parser.contents = $contents.map((i, p) ->
            $(p).text()
          ).get().join "\n"
        parser.digest = parser.contents.replace(/\n/g, " ").substr 0, 40

    toObject: ->
      {
        subject: @subject()
        from: @data.envelope.from
        shortname: @shortname
        url: @url
        user: @user
        datetime: @datetime
        contents: @contents
        digest: @digest
      }

    room: ->
      switch @shortname
        when "1movie"
          "#toiee"
        else
          "#support"

    createCustomMessage: ->
      [
        {
          room: @room()
        }
        {
          pretext: "*#{@subject()}* : <#{@url}|view comment>"
          fallback: "*#{@subject()}* : <#{@url}|view comment>"
          color: "#26c281"
          fields: [
            {
              title: "User"
              value: "Posted by <#{@user.profile}|#{@user.name}>"
              short: false
            },
            {
              title: "Comment"
              value: @contents
              short: true
            }
          ]
          mrkdwn_in: ["pretext", "fallback"]
        }
      ]
