# Description:
#   Run Cron job

util = require 'util'
CronJob = require("cron").CronJob
CSON = require 'cson'

jobs = CSON.parseFileSync 'config/jobs.cson'

module.exports = (robot) ->

  genCallback = (job) ->
    room = job.room || "#general"
    message = job.message
    if util.isArray message
      index = parseInt Math.random() * message.length, 10
      message = message[index]
    unless job.eachMonth?
      return () -> robot.send {room: room}, message

    nth_weeks = job.eachMonth.split(/,/)
    for nth_week, index in nth_weeks
      nth_week = parseInt nth_week.match(/(\d)/) and RegExp.$1, 10
      nth_weeks[index] = nth_week

    return () ->
      date = new Date()
      nth_week = Math.floor(date.getDate() / 7) + (date.getDate() % 7 > 0 ? 1 : 0)
      return unless nth_week in nth_weeks
      robot.send {room: room}, message

  for key, job of jobs
    jobs[key] = {
      cronTime: job.time,
      onTick: genCallback(job),
      start: true
    }

  for key, job of jobs
    console.log "register cron job: #{key}"
    console.log job
    try
      new CronJob job
    catch error
      console.log error
      console.log "error on #{key}"
