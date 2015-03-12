# CronJob list
# key: { time: "* * * * *", message: "...", room: "#general", start: true}
# You want to specify numbered week day e.g. 2nd mon,
# add eachMonth option e.g. eachMonth: "2nd".

module.exports =
  # 毎週水曜日に燃えるゴミの案内
  burnable:
    time: "0 17 * * 3"
    message: "明日は燃えるごみの日です。ごみをまとめましょう！＠茨木 @everyone"

  # 毎月第2, 4月曜日は缶・ビン・ペットボトルゴミの案内
  bottle:
    time: "0 17 * * 1"
    eachMonth: "2nd, 4th"
    message: "明日は缶・ビン・ペットボトルのごみの日です。＠茨木 @everyone"

  # 毎月1日は掃除を提案
  clean:
    time: "0 10 1 * *"
    message: "今日は月始めです。掃除でもしませんか？ @everyone"

  # 毎週月曜日は定例会議
  mtg:
    time: "0 10 * * 1"
    message: "後30分で定例会議開始ですよ！準備はOK？ :raised_hands: @everyone"

  greet:
    time: "0 09 * * 1-5"
    message: [
      "おはようございます！今日の目標は？ @everyone\n
      「目標設定」と話しかけてください！",
      "おはようさんです！今日は何しますか？ @everyone\n
      「目標設定」って言ってみてください。"]

  review:
    time: "27 18 * * 1-5"
    message: [
      "お疲れ様です。今日の目標は達成できましたか？ @everyone\n
      「目標達成」と話しかけてくださいね。",
      "もう夕方ですね、今日はどんな事をしましたか？ @everyone\n
      目標達成って叫んでも良いですよ！"]

  support_start:
    time: "0 10 * * 1-5"
    room: '#support'
    message: [
      "サポート開始しましょう！ @channel"
      "サポートとは、漢道である！うぬら、始められいぃぃっ！！ @channel"
      "Let's support! ウィ　ムッシュ〜〜 :feelsgood: @channel"]

  support_end:
    time: "0 12 * * 1-5"
    room: '#support'
    message: [
      "サポート終了時間です。お疲れ様でした @channel",
      "サポートの道を究めんとする、ぬしら、漢よのう・・・ご苦労！！ @channel",
      "Nice support!! ウィ　マドモワゼル〜〜 :panda_face: @channel"]
