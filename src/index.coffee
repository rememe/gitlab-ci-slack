express    = require 'express'
bodyParser = require 'body-parser'
request    = require 'request'

port     = process.env['PORT'] || 5000
slackUrl = process.env['SLACK_URL']

app = express()
app.use bodyParser.json()
app.use bodyParser.urlencoded { extended: true }


pipelineUrl = (body) ->
  "https://gitlab.com/#{body.project.path_with_namespace}/pipelines/#{body.object_attributes.id}"

branchUrl = (body) ->
  "https://gitlab.com/#{body.project.path_with_namespace}/commits/#{body.object_attributes.ref}"

getProjectUrl = (project) ->
  "https://gitlab.com/#{project}/environments"

getTime = (body) ->
  duration = body.object_attributes.duration
  min = Math.floor(duration  / 60)
  sec = Math.floor(duration  % 60)

  min = ('0' + min).slice(-2)
  sec = ('0' + sec).slice(-2)

  "#{min}:#{sec}"

app.post '/webhook/slack/deploy', (req, res) ->
  project = switch req.body.text
    when 'payments' then 'pingl-app/backend-administration'
    when 'backend' then 'pingl-app/backend'
    when 'customer' then 'pingl-app/frontend/customer'
    when 'staff' then 'pingl-app/frontend/staff'
    when 'admin' then 'pingl-app/frontend/admin'
    when 'landing' then 'pingl-app/landing-page'
    else undefined

  if project != undefined
    res.send { text: "Manage project at: <#{getProjectUrl(project)}|#{project}>" }
  else
    res.send { text: "Wrong project ID. Please use full form with group as namespace." }


app.post '/', (req, res) ->
  body = req.body

  if body.object_attributes.status != "success" && body.object_attributes.status != "failed" && body.object_attributes.status != "manual"
    res.send 'ok'
    return

  pipeline = body.object_attributes.id
  project = body.project.path_with_namespace
  projectName = body.project.name
  projectUrl = body.project.web_url
  branch = body.object_attributes.ref
  environment = if body.builds[0].status == 'manual' then body.builds[1].name else body.builds[0].name
  authorName = "#{body.user.name}"
  authorUsername = "#{body.user.username}"

  success = if body.object_attributes.status == "success" || body.object_attributes.status == "manual" then true else false
  status = if success then "passed" else "failed"

  pretext = "<#{projectUrl}|#{project}>: New build triggered by #{authorName} (#{authorUsername})"
  text = "Gitlab CI pipeline <#{pipelineUrl(body)}|##{pipeline}> of branch <#{branchUrl(body)}|#{branch}> #{status}."
  title = "#{projectName} - #{environment}"
  value = "in #{getTime(body)}"
  footer = if environment == "staging" then "Deploy to production manually <#{getProjectUrl(project)}|HERE>" else ""
  color = if success then "#36a64f" else "#ff2e2a"

  data =
    attachments: [{
      color: color
      pretext: pretext
      text: text
      footer: footer
      fields: [{
        title: title
        value: value
      }]
    }],
    username: "Gitlab CI - #{body.project.name}"

  request.post(url: slackUrl, body: data, json: true)
  res.send 'ok'

app.listen port
