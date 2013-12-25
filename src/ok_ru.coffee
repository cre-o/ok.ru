qs = require('querystring'); request = require('request')
_ = require('underscore')
md5 = require("blueimp-md5").md5

# Default options
requestOptions =
  applicationSecretKey: null
  applicationKey: null
  applicationId: null
  accessToken: null
  refreshToken: null
  # Default base urls where request's go
  restBase: 'http://api.odnoklassniki.ru/fb.do'
  refreshBase: 'http://api.odnoklassniki.ru/oauth/token.do'
  responseFormat: 'json'

exports.version = '1.2.0'

# It's like that and that's the way it is
class OkApi

  # We can construct requests on-fly
  # By doing this:
  #
  #   ok = require("./ok_ru")
  #   ok.setOptions(requestOptions)
  #   ok.setAccessToken(requestOptions)
  #
  # And using verbs: (POST, GET)
  #   ok.(get|post) { method: 'group.getUserGroupsByIds', group_id: groupId, uids: userIds }, (err, data) ->
  #     console.log response
  #
  #  ❨╯°□°❩╯︵┻━┻
  constructor: (method, postData, callback) ->
    validateOptions()
    makeRequest(method, postData, callback)

  # private methods goes below ^_^

  makeRequest = (method, postData, callback) ->
    requestedData =
      access_token: requestOptions['accessToken']
      application_key: requestOptions['applicationKey']
      sig: okSignature(postData)

    _.extend(requestedData, postData)

    switch method.toUpperCase()
      when 'POST'
        request.post {
          uri: requestOptions['restBase']
          json: true
          headers: 'content-type': 'application/x-www-form-urlencoded'
          body: qs.stringify(requestedData)
        }, (error, response, body) ->
          _responseHandler(error, response, body, callback)
      when 'GET'
        getUrl = "#{requestOptions['restBase']}?" + parametrize(requestedData, '&')
        request.get { uri: getUrl, json: true }, (error, response, body) ->
          _responseHandler(error, response, body, callback)
      else
        throw 'HTTP verb not supported'

  # Just apply that rules from http://apiok.ru/wiki/pages/viewpage.action?pageId=42476522
  okSignature = (postData) ->
    # Additional params that included into signature
    postData['application_key'] = requestOptions['applicationKey']

    sortedParams = parametrize(postData)
    secret = md5(requestOptions['accessToken'] + requestOptions['applicationSecretKey'])

    md5(sortedParams + secret)


  # Method that helps made string of parameters for objects
  parametrize = (obj, join = false) ->
    arrayOfArrays = _.pairs(obj).sort()

    symbol = if join then '&' else ''

    sortedParams = ''
    _.each arrayOfArrays, (value) ->
      sortedParams += "#{_.first(value)}=#{_.last(value)}" + symbol

    return sortedParams

  validateOptions = ->
    unless requestOptions['applicationKey']? || requestOptions['applicationId']? || requestOptions['applicationSecretKey']?
      throw 'Please setup requestOptions with valid params. @see https://github.com/astronz/ok.ru'
    unless requestOptions['accessToken']?
      throw 'AccessToken does not initialized. @see https://github.com/astronz/ok.ru'


# Exports api as class
exports.api = OkApi

_responseHandler = (error, response, body, callback) ->
  if error? # HTTP error
    callback(error, body, response)
  else
    error = body if body.hasOwnProperty('error_code') # API error
    callback(error, body, response)

#
# Refresh user token to new one
#
exports.refresh = (refreshToken, callback) ->
  requestOptions['refreshToken'] = refreshToken

  refresh_params =
    refresh_token: requestOptions['refreshToken']
    grant_type: 'refresh_token',
    client_id: requestOptions['applicationId'],
    client_secret: requestOptions['applicationSecretKey']

  request.post {
    uri: requestOptions['refreshBase']
    json: true
    headers: 'content-type': 'application/x-www-form-urlencoded'
    body: qs.stringify(refresh_params)
  }, (error, response, body) ->
    _responseHandler(error, response, body, callback)

#
# Prepares POST request for API
#
exports.post = (params, callback) ->
  new OkApi 'POST', params, callback

#
# Prepares POST request for API
#
exports.get = (params, callback) ->
  new OkApi 'GET', params, callback

# Set needed accessToken
exports.setAccessToken = (token) ->
  _.extend(requestOptions, {accessToken: token})

# Gets accesToken
exports.getAccessToken = ->
  requestOptions['accessToken']

# Setup global requestOptions
exports.setOptions = (options) ->
  if typeof options == 'object'
    _.extend(requestOptions, options)

# Gets options
exports.getOptions = ->
  requestOptions
