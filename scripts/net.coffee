# Description:
#   Provide network commands
#
# Commands:
#   hubot nslookup <host> - [net] lookup host's ip-address and host name resolved by ip-address

URL = require "url"
DNS = require "dns"

module.exports = (robot) ->
  robot.respond /nslookup (\S+)/i, (msg) ->
    arg = msg.match[1]
    if /^https?:\/\//i.test arg
      host = URL.parse(arg).host
    else if /.+\//.test arg
      host = arg.split(/\//)[0]
    else
      host = msg.match[1]

    lookup host, (result) ->
      if result.err
        msg.send "lookup できません！"
      else
        text = "IP: #{result.address}\n"
        text += "Domains:\n" + result.domains.join("\n") if result.domains?

        if robot.adapterName is "slack"
          attachment = {
            pretext: "*#{host}*"
            fallback: text
            color: "#26c281"
            fields: [
              {
                title: "IpAddress"
                value: result.address
                short: true
              }
            ]
            mrkdwn_in: ["pretext", "fallback"]
          }
          if result.domains
            for domain, i in result.domains
              title = "Domain"
              title += "#{i+1}" if result.domains.length > 1
              attachment.fields.push {
                title: title
                value: domain
                short: true
              }
          data = {
            channel:     "#" + msg.envelope.user.room
            attachments: [attachment]
          }

          robot.emit "slack.attachment", data


        else
          msg.send text

  lookup = (host, callback) ->
    result = {}
    DNS.lookup host, (err, address) ->
      if err
        result.err = err
        callback.call robot, result
      else
        result.address = address
        DNS.reverse address, (err, domains) ->
          unless err
            result.domains = domains
          callback.call robot, result
