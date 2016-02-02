# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
  robot.respond /door (pls|please|plz)/i, (res) ->

    reply_msg = "Done ya kbeer el m3lmeen :D"

    #is this trolling ?
    if res.user.name == "ekoshairy"
        reply_msg = "Done ya kbeeret el m3lmeen :D"

    robot.http("http://192.168.1.199:8080")
          .get() (err, response, body) ->
            res.reply reply_msg
            return

