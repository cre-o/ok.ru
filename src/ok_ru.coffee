sys = require('util'); rest = require('restler')
_ = require('underscore')
crypto = require('crypto')

# Default options
requestOptions =
  applicationSecretKey: null
  applicationKey: null
  applicationId: null
  accessToken: null
  refreshToken: null
  defaultVerb: 'post'

exports.version = '0.0.5'

# It's like that and that's the way it is
class OkApi

  # Default base urls where request's go
  @REST_BASE: 'http://api.odnoklassniki.ru/fb.do'
  @REFRESH_BASE: 'http://api.odnoklassniki.ru/oauth/token.do'

  # We can construct requests on-fly
  # By doing this:
  #
  #   ok = require("./ok_ru")
  #   ok.setOptions(requestOptions)
  #   ok.setAccessToken(requestOptions)
  #
  #   new ok.api { method: 'group.getUserGroupsByIds', group_id: groupId, uids: userIds }, (err, response) ->
  #     console.log response
  #
  # -OR-
  #
  # By using verbs: (POST, GET)
  #   ok.(get|post) { method: 'group.getUserGroupsByIds', group_id: groupId, uids: userIds }, (err, response) ->
  #     console.log response
  #
  #  ❨╯°□°❩╯︵┻━┻
  constructor: (method, postData, callback) ->

    if typeof postData == 'function'
      callback = postData

    if typeof method == 'object'
      postData = method
      method = requestOptions['defaultVerb']

    makeRequest(method, postData, callback)

  # private methods goes below ^_^

  makeRequest = (method, postData, callback) ->
    requestedData =
      access_token: requestOptions['accessToken']
      application_key: requestOptions['applicationKey']
      sig: okSignature(postData)

    _.extend(requestedData, postData)

    error = []
    switch method.toUpperCase()
      when 'POST'

        rest.post(OkApi.REST_BASE, {
          data: requestedData
        }).on 'complete', (data) ->
          if data['error_code']?
            error.push data

          callback(error, data)

      when 'GET'
        getUrl = "#{OkApi.REST_BASE}?" + parametrize(requestedData, '&')
        rest.get(getUrl).on 'complete', (data) ->
          if data['error_code']?
            error.push data

          callback(error, data)

      else
        console.log 'HTTP verb not supported'

  # Just apply that rules from http://apiok.ru/wiki/pages/viewpage.action?pageId=42476522
  okSignature = (postData) ->
    postData['application_key'] = requestOptions['applicationKey']

    sortedParams = parametrize(postData)

    hashStr = "#{requestOptions['accessToken']}#{requestOptions['applicationSecretKey']}"
    secret  = crypto.createHash('md5').update(hashStr).digest("hex")
    # Hurray!
    crypto.createHash('md5').update("#{sortedParams}#{secret}").digest("hex")


  # Method that helps made string of parameters for objects
  parametrize = (obj, join = false) ->
    arrayOfArrays = _.pairs(obj).sort()

    symbol = if join then '&' else ''

    sortedParams = ''
    _.each arrayOfArrays, (value) ->
      sortedParams += "#{_.first(value)}=#{_.last(value)}" + symbol

    return sortedParams


# Exports api as class
exports.api = OkApi

#
# Refresh user token to new one
#
exports.refresh = (refreshToken = '', callback) ->
  requestOptions['refreshToken'] = refreshToken if refreshToken?
  unless requestOptions['refreshToken']?
    console.log 'RefreshToken not valid for Refresh action'
    return false

  refresh_params =
    refresh_token: requestOptions['refreshToken']
    grant_type: 'refresh_token',
    client_id: requestOptions['applicationId'],
    client_secret: requestOptions['applicationSecretKey']

  rest.post(OkApi.REFRESH_BASE, {
            data: refresh_params
          }).on 'complete', (data) ->
            callback(data)

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
