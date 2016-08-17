{before, describe, it} = global

path = require 'path'
helpers = require('yeoman-test')
assert = require('yeoman-assert')

GENERATOR_NAME = 'app'
DEST = path.join __dirname, '..', 'temp', "slurry-#{GENERATOR_NAME}"

describe 'app', ->
  before 'run the helper', (done) ->
    helpers
      .run path.join __dirname, '..', 'app'
      .inDir DEST
      .withOptions
        realname: 'Alex Gorbatchev'
        githubUrl: 'https://github.com/alexgorbatchev'
      .withPrompts
        githubUser: 'alexgorbatchev'
        generatorName: GENERATOR_NAME
        passportName: 'passport-app'
      .on 'end', done

  it 'creates expected files', ->
    assert.file '''
      Dockerfile
      src/api-strategy.coffee
      src/configurations/public-filtered-stream/action.coffee
      src/configurations/public-filtered-stream/form.cson
      src/configurations/public-filtered-stream/index.coffee
      src/configurations/public-filtered-stream/job.coffee
      src/configurations/public-filtered-stream/configure.cson
      src/configurations/public-filtered-stream/response.cson
      test/test_helper.coffee
      test/mocha.opts
      command.js
      command.coffee
      coffeelint.json
      .gitignore
      .travis.yml
      LICENSE
      README.md
      package.json
    '''.split /\s+/g
