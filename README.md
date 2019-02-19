# gitlab-ci-slack

Tiny web server to get Travis-like Slack notifications
with Gitlab CI.

## Configure

First, set the following environment variables.

```javascript
port     = process.env['PORT'] || 5000
slackUrl = process.env['SLACK_URL']
```

* `PORT` is the port the webapp will be listening to
* `SLACK_URL` is Slack webhooks URL

## Running

Just run

```sh
$ npm install
$ npm start
```

and add a Gitlab CI webhook to point to the server.

## Deploying

The app works perfectly on a free heroku dyno, if you have an account it's as simple as pressing the button below and setting the relevant config variables in the web admin console.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

