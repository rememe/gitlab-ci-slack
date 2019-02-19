express    = require 'express'
bodyParser = require 'body-parser'
request    = require 'request'

port     = process.env['PORT'] || 5000
slackUrl = process.env['SLACK_URL']

app = express()
app.use bodyParser.json()


pipelineUrl = (body) ->
  "https://gitlab.com/#{body.project.path_with_namespace}/pipelines/#{body.object_attributes.id}"

branchUrl = (body) ->
  "https://gitlab.com/#{body.project.path_with_namespace}/commits/#{body.object_attributes.ref}"

getTime = (body) ->
  duration = body.object_attributes.duration
  min = Math.floor((duration / 1000) / 60)
  sec = Math.floor((duration / 1000) % 60)

  min = ('0' + min).slice(-2)
  sec = ('0' + sec).slice(-2)

  "#{min}:#{sec}"

app.post '/', (req, res) ->
  body = req.body

  if body.object_attributes.status != "success" && body.object_attributes.status != "failed"
    res.send 'ok'
    return

  pipeline = body.object_attributes.id
  projectName = body.project.path_with_namespace
  projectUrl = body.project.web_url
  branch = body.object_attributes.ref
  authorName = "#{body.user.name}"
  authorUsername = "#{body.user.username}"

  success = if body.object_attributes.status == "success" then true else false
  status = if success then "passed" else "failed"

  pretext = "<#{projectUrl}|#{projectName}>: Gitlab CI pipeline <#{pipelineUrl(body)}|##{pipeline}> of branch <#{branchUrl(body)}|#{branch}> #{status}."
  text = "by #{authorName} (#{authorUsername})"
  title = branch
  value = "in #{getTime(body)}"
  color = if success then "#36a64f" else "#ff2e2a"

  data =
    attachments: [{
      color: color
      pretext: pretext
      text: text
      fields: [{
        title: title
        value: value
      }]
    }],
    username: "Gitlab CI - #{body.project.name}"

  request.post(url: slackUrl, body: data, json: true)
  res.send 'ok'

app.listen port
