# Description:
#   hubot に誰がどんな強み（資質）を持っているか記憶させる／聞く
#
# Commands:
#   hubot <user>の強みは何？
#   hubot <user>のN番の強みは何？
#   hubot <user>の強みはxxです。
#   hubot <user>の強みはxxとyy、zzです。
#   hubot <user>のN番の強みはxxです。
#   hubot 皆の強みを教えて！

CSON = require 'cson'

class StrengthList
  @strengths = CSON.parseFileSync 'config/strengths.cson'

  # Return List or Detail of specified strength name
  #
  # @param string name name or title of strength
  @get: (name) ->
    unless name?
      return @strengths

    if @strengths[name]?
      return @strengths[name]
    else
      for key, strength of @strengths
        if name == strength.title
          return strength
    return false

  @getTitle: (name) ->
    strength = @get name

    return strength.title if strength.title?

module.exports = (robot) ->

  respond_user_strength = (msg) ->
    [user_name, strength_label, rank_index] = msg.data
    strength_name = robot.brain.data.strength[user_name][rank_index]
    strength_title = StrengthList.getTitle(strength_name)
    text_pares = [
      ["やだなぁ", "じゃないですか"],
      ["ご存知", "ですよ！"],
      ["しびれるぅ！", "だッッッ！！"],
      ["ご主人様、", "でございます。"],
      ["神よ", "であることをお許し下さい。Amen"]
    ]
    [prefix, suffix] = text_pares[Math.floor Math.random() * text_pares.length]

    if strength_title?
      msg.send "#{prefix}#{user_name}の#{rank_index+1}番の#{strength_label}は *#{strength_title}* #{suffix}"
    else
      msg.send "登録されていません！"

  save_user_strength = (msg) ->
    [user_name, strength_label, strength_text, rank_index] = msg.data
    strength_arr = strength_text.split /\s*[,、]\s*/
    ranking = []
    robot.brain.data.strength = {} unless robot.brain.data.strength
    robot.brain.data.strength[user_name] = []

    for value, i in strength_arr
      strength = StrengthList.get value
      if strength != false
        ranking.push strength

    if ranking.length > 0
      if ranking.length == 1
        strength = ranking[0]
        robot.brain.data.strength[user_name][rank_index] = strength.title
        msg.send "#{user_name}の#{rank_index+1}番の#{strength_label}は#{strength.title}ですね。"
      else
        for strength, i in ranking
          robot.brain.data.strength[user_name][i] = strength.title
          msg.send "#{user_name}の#{i+1}番の#{strength_label}は#{strength.title}ですね。"
    else
      msg.send "該当する#{strength_label}が見当たりません。"

  robot.respond /@?([a-z0-9]+)\s*の(強み|資質)は(何(だっけ)?)?？/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[2],
      0
    ]
    respond_user_strength msg

  robot.respond /@?([a-z0-9]+)\s*の(\d)番目?の(強み|資質)は(何(だっけ)?)?？/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[3],
      msg.match[2]-1
    ]
    respond_user_strength msg


  robot.respond /@?([a-z0-9]+)\s*の(強み|資質)は(?!何|？)(.+?)(です。?)?$/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[2],
      msg.match[3],
      0
    ]
    msg.data.push 0
    save_user_strength msg

  robot.respond /@?([a-z0-9]+)\s*の(\d)番目?の(強み|資質)は(?!何|？)(.+?)(です。?)?$/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[3],
      msg.match[4],
      msg.match[2]-1
    ]
    save_user_strength msg

  #robot.respond /strength list please/i, (msg) ->
  robot.respond /(皆|みんな)の(強み|資質)を教えて/i, (msg) ->
    text = ""
    for user_name, strength_ranking of robot.brain.data.strength
      text += "*#{user_name}* の強み：\n"
      for rank_index, strength_title of strength_ranking
        rank_index = parseInt(rank_index, 10)
        text += "#{rank_index+1}位：#{strength_title}\n"
      text += "\n"
    msg.send text

  robot.respond /Team card/i, (msg) ->
    AsciiTable = require 'ascii-table'
    table = new AsciiTable 'Team Card'

    users = []
    headings = ["#"]
    for user_name, strength_title of robot.brain.data.strength
      users.push user_name
      headings.push user_name

    table.setHeading.apply(table, headings)

    for strength_name, strength of StrengthList.get()
      row = [strength.title]
      for user_name in users
        for strenght_title in robot.brain.data.strength[user_name]
          if strength_title.toString() == strength.title.toString()
            row.push "◯"
          else
            row.push " "
      table.addRow.apply(table, row)

    table.setAlign 1, AsciiTable.RIGHT

    msg.send table.toString()
