speech = require 'google-speech-api'
EventEmitter = require('events').EventEmitter
spawn = require('child_process').spawn

class Speakable extends EventEmitter
  constructor: (@options = {}) ->
    EventEmitter.call @

    @options.threshold ?= 0.5
    @options.lang ?= 'en-US'

    @recBuffer = []

    @recRunning = false
    @apiResult = {}
    @apiLang = @options.lang
    @cmd = 'sox'
    @cmdArgs = [
      '-q'
      '-b'
      '16'
      '-d'
      '-t'
      'flac'
      '-'
      'rate'
      '16000'
      'channels'
      '1'
      'silence'
      '1'
      '0.1'
      @options.threshold + '%'
      '1'
      '1.0'
      @options.threshold + '%'
    ]
  postVoiceData: =>

    # speech options, (err, result) ->
    #   @recBuffer = []
    #   res.setEncoding
    #
    #
    # self.recBuffer = [];
    # if(res.statusCode !== 200) {
    #   return self.emit(
    #     'error',
    #     'Non-200 answer from Google Speech API (' + res.statusCode + ')'
    #   );
    # }
    # res.setEncoding('utf8');
    # res.on('data', function (chunk) {
    #   self.apiResult = JSON.parse(chunk);
    # });
    # res.on('end', function() {
    #   self.parseResult();
    # });

    options =
      file: new Buffer @recBuffer
      key: 'AIzaSyC8KS0RLfK4KOwWXIzBccORJ4Xz8wXzZdI'
      lang: @apiLang
      filetype: 'flac'

    speech options, (err, result) =>
      if err then @emit 'error', err
      else @emit 'result', result

  listen: =>
    rec = spawn @cmd, @cmdArgs, stdio: 'pipe'
    rec.stdout.on 'readable', -> @emit 'ready'
    rec.stdout.setEncoding 'binary'
    rec.stdout.on 'data', (data) =>
      if not @recRunning
        @emit 'start'
        @recRunning = true
      @recBuffer.push datum for datum in data

    rec.stderr.setEncoding 'utf8'
    rec.stderr.on 'data', console.log

    rec.on 'close', (code) =>
      @recRunning = false
      if code then @emit 'error', 'sox exited with code ' + code
      @emit 'stop'
      @postVoiceData()

  resetVoice: =>
    @recBuffer = []

listener = new Speakable()

listener.on 'start', -> console.log 'start'
listener.on 'stop', -> console.log 'stop'
listener.on 'ready', -> console.log 'ready'
listener.on 'result', console.log

listener.listen()
