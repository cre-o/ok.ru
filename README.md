## Ok.ru API with node

This npm module allows you to simplify API requests to odnoklassniki.ru
## Getting started

Typical code may looks like this

```coffeescript
ok = require("ok.ru")

# Basic configuration params
requestOptions = {
  applicationSecretKey: '{secretKey}',
  applicationKey: '{applicationKey}',
  applicationId: '{applicationId}',
}

ok.setOptions(requestOptions)
# You can specify accessToken in requestOptions or separately
# For example: if you have many users and you whant to iterate through them
ok.setAccessToken('{access_token}');

# All data passed in Object
ok.post { method: 'group.getUserGroupsV2' }, (err, data) ->
  # Some actions with data

# You also can use alternative syntax
request = new ok.api { method: 'group.getMembers', uid: '999999' }, (err, data) ->
  # Some actions with data

# You can also specify types of requests
ok.post, ok.get

# Or pass in, as argument
new ok.api 'post', { method: 'users.isAppUser' }, (err, data) ->
  # some actions with data

```

Refresh user token method
```coffeescript
ok.refresh '{refresh_token}', (err, data) ->
  # data => new token
```

Enjoy!


TODO
----
* What do you need? Let me know or fork.
