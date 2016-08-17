path       = require 'path'
htmlWiring = require 'html-wiring'
yeoman     = require 'yeoman-generator'
_          = require 'lodash'
helpers    = require './helpers'

class OctobluServiceGenerator extends yeoman.Base
  constructor: (args, options) ->
    super
    @option 'github-user'
    @currentYear = (new Date()).getFullYear()
    {@realname, @githubUrl} = options
    @skipInstall = options['skip-install']
    @githubUser  = options['github-user']
    @pkg = JSON.parse htmlWiring.readFileAsString path.join __dirname, '../package.json'

  initializing: =>
    @appname = _.kebabCase @appname
    @noslurry = _.replace @appname, /^slurry-/, ''
    @env.error 'appname must start with "slurry-", exiting.' unless _.startsWith @appname, 'slurry-'

  prompting: =>
    return if @githubUser?

    done = @async()

    prompts = [
      name: 'githubUser'
      message: 'Would you mind telling me your username on GitHub?'
      default: 'octoblu'
    ]

    @prompt prompts, (props) =>
      @githubUser = props.githubUser
      done()

  userInfo: =>
    return if @realname? and @githubUrl?

    done = @async()

    helpers.githubUserInfo @githubUser, (error, res) =>
      @env.error error if error?
      @realname = res.name
      @email = res.email
      @githubUrl = res.html_url
      done()

  configuring: =>
    @copy '_gitignore', '.gitignore'

  writing: =>
    filePrefix     = _.kebabCase @noslurry
    instancePrefix = _.camelCase @noslurry
    classPrefix    = _.upperFirst instancePrefix
    constantPrefix = _.toUpper _.snakeCase @noslurry

    context = {
      @githubUrl
      @realname
      @appname
      filePrefix
      classPrefix
      instancePrefix
      constantPrefix
    }
    @template "_package.json", "package.json", context
    @template "src/_api-strategy.coffee", "src/api-strategy.coffee", context
    @template "src/configurations/public-filtered-stream/_action.coffee", "src/configurations/public-filtered-stream/action.coffee", context
    @template "src/configurations/public-filtered-stream/_configure.cson", "src/configurations/public-filtered-stream/configure.cson", context
    @template "src/configurations/public-filtered-stream/_index.coffee", "src/configurations/public-filtered-stream/index.coffee", context
    @template "src/configurations/public-filtered-stream/_job.coffee", "src/configurations/public-filtered-stream/job.coffee", context
    @template "src/configurations/public-filtered-stream/_form.cson", "src/configurations/public-filtered-stream/form.cson", context
    @template "src/configurations/public-filtered-stream/_response.cson", "src/configurations/public-filtered-stream/response.cson", context
    @template "src/jobs/_gitignore", "src/jobs/.gitignore", context
    @template "test/_mocha.opts", "test/mocha.opts", context
    @template "test/_test_helper.coffee", "test/test_helper.coffee", context
    @template "_command.js", "command.js", context
    @template "_command.coffee", "command.coffee", context
    @template "_coffeelint.json", "coffeelint.json", context
    @template "_travis.yml", ".travis.yml", context
    @template "_Dockerfile", "Dockerfile", context
    @template "_dockerignore", ".dockerignore", context
    @template "README.md", "README.md", context
    @template "LICENSE", "LICENSE", context

  install: =>
    return if @skipInstall

    @installDependencies npm: true, bower: false
    @npmInstall "passport-#{@noslurry}", save: true

  end: =>
    return if @skipInstall
    @log "\nBy the way, I installed 'passport-#{@noslurry}', so if that's not right, you should fix it.\n"

module.exports = OctobluServiceGenerator
