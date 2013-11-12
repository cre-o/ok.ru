require('js-yaml')
assert = require('assert')
expect = require('chai').expect
ok = require('../lib/ok_ru.js')

describe "ok.ru", ->
	before ->
  	@settings = require('./settings.yml')
  	@accessToken = null # You can set up token here
  	@refreshToken = null # You can set up refresh_token here

	describe "Initialization", ->
    it "#getOptions", ->
    	baseOptions = ok.getOptions()
    	expect(baseOptions).to.have.property('applicationSecretKey')
    	expect(baseOptions).to.have.property('applicationKey')
    	expect(baseOptions).to.have.property('applicationId')
    	expect(baseOptions).to.have.property('accessToken')
    	expect(baseOptions).to.have.property('refreshToken')
    	expect(baseOptions).to.have.property('restBase')
    	expect(baseOptions).to.have.property('refreshBase')

    it '#get', ->
    	expect(ok.get).to.be.a('function')

    it '#post', ->
    	expect(ok.get).to.be.a('function')

   it 'Needs odnoklassniki app params', ->
   		error = ->
   			ok.get({method: 'test'})
   		expect(error).to.throw(/Please setup requestOptions with valid params./)

   	it 'Needs accessToken', ->
   		ok.setOptions {
   			applicationId: @settings.app.app_id
   			applicationKey: @settings.app.public_key
   			applicationSecretKey: @settings.app.app_secret_key
   			accessToken: null
   		}

   		error = ->
   			ok.get({method: 'test'})
   		expect(error).to.throw(/AccessToken does not initialized./)

  describe 'REST processing', ->
  	before ->
  		default_options = {
  			applicationId: @settings.app.app_id
  			applicationKey: @settings.app.public_key
  			applicationSecretKey: @settings.app.app_secret_key
  			accessToken: if @settings.tokens.access_token? then @settings.tokens.access_token else @accessToken
  			refreshToken: if @settings.tokens.refresh_token? then @settings.tokens.refresh_token else @refreshToken
	  	}

	  	ok.setOptions(default_options)

	  it 'Needs valid accessToken', (done) ->
	  	ok.get { method: 'users.getCurrentUser' }, (err, data) ->
	  		if data.error_code?
	  			throw "Request for validate access token failed with message: #{data.error_msg}"
	  		else
	  			expect(data).to.have.property('uid')
	  			done()

  	it 'Send data via POST method', (done) ->
  		ok.post { method: 'users.isAppUser' }, (err, data) ->
  			expect(data).to.be.a('boolean')
  			done()

    it 'Send data via GET method', (done) ->
    	ok.get { method: 'users.isAppUser' }, (err, data) ->
  			expect(data).to.be.a('boolean')
  			done()

  	it 'Can send many arguments', (done) ->
  		ok.post { method: 'users.getInfo', uids: '554914033022', fields: 'uid, first_name, last_name, gender, age, online, url_profile' },
  		(err, data) ->
  			# it returns array
  			expect(data[0]).to.have.property('uid')
  			done()

  	it 'Should refresh token', (done) ->
  		refresh_token = ok.getOptions()['refreshToken']
  		ok.refresh refresh_token, (err, data) ->
  			expect(data).to.have.property('access_token')
  			done()

   it 'Should processing request errors', (done) ->
  		ok.setOptions(
  			{ accessToken: 'Invalid' } # Invalid access_token
  		)

  		ok.post { method: 'users.isAppUser' }, (err, data, response) ->
  			expect(err).to.have.property('error_msg')
  			expect(response).to.exist
  			done()

