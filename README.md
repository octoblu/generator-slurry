# generator-slurry

[![Dependency status](http://img.shields.io/david/octoblu/generator-slurry.svg?style=flat)](https://david-dm.org/octoblu/generator-slurry)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/generator-slurry.svg?style=flat)](https://david-dm.org/octoblu/generator-slurry#info=devDependencies)
[![Build Status](http://img.shields.io/travis/octoblu/generator-slurry.svg?style=flat&branch=master)](https://travis-ci.org/octoblu/generator-slurry)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Slurry Service](#slurry-service)
  - [Managing API credentials](#managing-api-credentials)
    - [Storing API Credentials](#storing-api-credentials)
      - [Updating API Credentials](#updating-api-credentials)
      - [Revoking API Access](#revoking-api-access)
  - [Receiving incoming Meshblu messages.](#receiving-incoming-meshblu-messages)
  - [Mapping messages to API calls.](#mapping-messages-to-api-calls)
  - [Mapping API call results to a response](#mapping-api-call-results-to-a-response)
  - [Responding via Meshblu](#responding-via-meshblu)
- [Creating a Channel](#creating-a-channel)
  - [Install yo and the generator](#install-yo-and-the-generator)
  - [Create a new project and run the generator](#create-a-new-project-and-run-the-generator)
  - [Modify the passport configuration](#modify-the-passport-configuration)
    - [User Required Properties](#user-required-properties)
        - [Example](#example)
  - [Create a configuration](#create-a-configuration)
    - [Configuration directory format](#configuration-directory-format)
  - [Create a job](#create-a-job)
    - [Job directory format](#job-directory-format)
      - [list-events-by-user (Job directory)](#list-events-by-user-job-directory)
      - [action.coffee](#actioncoffee)
      - [index.coffee](#indexcoffee)
      - [job.coffee](#jobcoffee)
        - [type Job](#type-job)
        - [function job.do](#function-jobdo)
      - [form.cson](#formcson)
      - [message.cson](#messagecson)
      - [response.cson](#responsecson)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Slurry Service

Before creating an Slurry Service, it helps to understand the role it plays in mediating the management of API credentials, mapping incoming Meshblu messages to API calls, and mapping the results to a Meshblu response message.

## Managing API credentials

The credentials management portion of an Slurry Service has N  goals:

* Store API credentials so they may be retrieved by the service to make API calls.
* Allow multiple Octoblu Users and Meshblu Devices to share the same set of credentials.
* Use Meshblu's whitelists to manage who has access to consume the API.
* Make it safe to transfer ownership of a device with API access without revealing any credentials.
* To allow anyone with the ability to authenticate as the API user to revoke access from any devices that authenticated previously.

### Storing API Credentials

The user account information is encrypted using the Slurry Service's private key, and then stored on a `credentials device` that only the Slurry Service has permission to discover.

#### Updating API Credentials

There are cases in which the API credentials may need to be updated. For example, a user reauthenticate with the API, generating a new access token and revoking the previous token.

If a user can prove to the Slurry Service that they have control over the user account the credentials device points to (generally by redoing the oauth process), they may overwrite the credentials with new credentials.

#### Revoking API Access

After the user has proven to the Slurry Service that they have control over the user account the credentials device points to, they will be given:

* The ability to list all `user devices` that currently have the ability to consume the API.
* The ability to revoke access from any of those `user devices`.
* The ability to create additional `user devices` with access.

## Receiving incoming Meshblu messages.

A consumer of the API should not need to be aware of the existence of the `credentials device`. Instead, they use the `user device` to interact with the API. The `credentials device` has a `message.received` subscription to the `user device`, which lets it intercept messages sent to the `user device`. On receiving an intercepted message, it forwards the message into the Slurry Service via a webhook. The Slurry Service can then access and decrypt the credentials from the `credentials device` map the message to an API call.

## Mapping messages to API calls.

The Slurry Service translates the incoming message into a valid API request. We recommend that the actual execution of the API request be handled by a third party NPM module if one is available. For example, out [octoblu/slurry-github](https://github.com/octoblu/slurry-github) service uses the [Github NPM module](https://www.npmjs.com/package/github).

## Mapping API call results to a response

After the Slurry Service receives the result of the API call, it should format a response to send back to the client. We recommend limiting the amount of data included in the response to the bare minimum required to be useful, and only adding to it after actual users request the data. It is strongly discouraged to pass the API result object directly back as the response data without at least whitelisting the properties it sends back.

For example, a list-events-by-user call to the Github API may result in an event object that contains a username that performed the event, an event type, dozens of URLs that can be accessed to find more information about the event, as well as other miscellaneous data. In our implementation, we limit the response properties to just the handful that are critical to be useful, give them more expressive names, and flatten them into a simpler data structure.

## Broadcast streaming messages to Meshblu

The Slurry Service receives streaming API results, it will format a broadcast and emit it from the user device. This device may be used in flows or other Octoblu workflows to access API data quickly and without the need for polling.

```coffee
processResults: (results)=>
  _.map results, (result) =>
    {
      createdAt:   result.created_at
      description: result.payload.description
      type:        result.type
      username:    result.actor.display_login
    }
```

## Responding via Meshblu

After the mapping is complete, the Slurry Service should respond to the device that originally sent the message. Usually, the message comes from a `flow` device to a `user device` and is intercepted by the `credentials device`. The `flow` will not know about the existance of the `credentials device`, and will generally not allow the `credentials device` to send it messages. To address this, the `user device` has the `credentials device` in its `message.as` whitelist.

So, to send a meshblu response, the `credentials device` will send the `flow` a direct message as the `user device`.

# Creating an Slurry

## Install yo and the generator

```shell
npm install -g yo generator-slurry
```

## Create a new project and run the generator

Note that the project directory name must start with `slurry-`

```shell
mkdir slurry-github
cd slurry-github
yo slurry
```

## Setting up the Oauth Device with Octoblu

An Oauth device must be [registered with Octoblu](https://app.octoblu.com/node-wizard/add/551478c1537bdd6e20c9c608). After the device has been created, use the `Credentials: generate` (and download) link to pull down a `meshblu.json`. Save that `meshblu.json` to the root of your slurry directory (This file should not be checked in, and has been added to the project's `.gitignore`)

Use [slurry-doctor](https://github.com/octoblu/slurry-doctor) to finish configuring the device.

## Modify the passport configuration

The passport configuration is available in `src/api-strategy`. It's purpose is to map the API oauth profile to some required slurry values in the `onAuthorization` function.

The callback passed in to the `onAuthorization` function expects a user object as its second parameter. The user object will be encrypted using the service's private key and stored on a credentials device that only the API service will have access to.

The properties listed are all required. However, the developer can add whatever additional properties they'd like. Keep in mind that every attribute that is not under the `secrets` key may be made available users authenticated by the API. In other words, if a user uses Oauth to authenicate the slurry service as Twitter user @sqrtofsaturn, they may get access to all of the properties in the user object that are not under the `secrets` key.

If you wish to have an API that doesn't require authentication, we recommend using [passport-slurry-passthru](https://github.com/octoblu/passport-slurry-passthru). It will use the user's Meshblu UUID to identify the `Credentials Device`.

### User Required Properties

* `id`  The unique identifier that the API uses to identify this user. Is often an integer value.
* `username`  The visual identifier that the user would recognize as their username. It is used as the name of the device created for the user.
* `secrets`  Nothing under this key should ever be made available to anyone other than the Slurry service itself.
  * `credentials` The credentials needed to make API requests.
    * `secret` The token used to make API requests.
    * `refreshToken` The token used to generate a new `secret` when it expires.

##### Example

```coffee
onAuthorization: (accessToken, refreshToken, profile, callback) =>
  callback null, {
    id: profile.id
    username: profile.username
    secrets:
      credentials:
        secret: accessToken
        refreshToken: refreshToken
  }
```

## Create a configuration

Configurations are stored in src/configurations. When the service first comes online, it will crawl through the src/configurations directory and generate a directory for each configuration that it finds. This generator will create one demo configuration for you. However, unless you're creating a Twitter Slurry, the example will not be very useful.

### Configuration directory format

```
src/
├── configurations
│   ├── autobot
│   │   ├── action.coffee
│   │   ├── index.coffee
│   │   ├── job.coffee
│   │   ├── form.cson
│   │   ├── configuration.cson
```

## Create a job

Jobs are stored in src/jobs. When the service first comes online, it will crawl through the src/jobs directory and generate a directory for each job that it finds. This generator will create one demo job for you. However, unless you're creating a Github Slurry, the example will not be very useful.

### Job directory format

```
src/
├── jobs
│   ├── list-events-by-user
│   │   ├── action.coffee
│   │   ├── index.coffee
│   │   ├── job.coffee
│   │   ├── form.cson
│   │   ├── message.cson
│   │   └── response.cson
```

#### list-events-by-user (Job directory)

The directory name will titleized be used as the job type identifier. For example, `list-events-by-user` will become the job type `ListEventsByUser`. The job will be executed by the message handler for incoming messages with a `metadata.jobType` that matches the job type identifier generated.

#### action.coffee

`action.coffee` exports a function that will be called for matching messages with the device options and the message, along with a callback that must be called to respond to the requester. The purpose of `action.coffee` is to map the function call API of the message handler to the Object Oriented API of the job. This file does not generally need to be modified.

#### index.coffee

`index.coffee` exports the functions and schema that make up the job in a standard structure. This file does not generally need to be modified.

#### job.coffee

`job.coffee` is responsible for 4 things:

1. Take the incoming request message and decrypted secrets and maps them to an API call.
2. Make the API call.
3. Map the API response to the job's response schema.
4. Respond to the message by calling the `callback` with either an error or a properly formatted response.

##### type Job

```coffee
new Job({
  # encrypted portion of the credentials device, decrypted
  encrypted:
    # Anything in secrets should never be returned as a result of a message.
    secrets:
      # The API credentials needed to make a request.
      credentials:
        # The token used to make API requests.
        token: "abcd1234"
        # The token used to generate a new `secret` when it expires.
        refreshToken:  "abcd1234"
})
```

##### function job.do

```coffee
job.do({data}, callback)
```

`data` should have the structure defined in `message.cson`. Combined with the `credentials` from the Job constructor, it will provide all the information needed to perform the API request.


The `callback` passed in to the `do` functions expects to be called with either an `error` as its first argument, or with `null` as its first argument and a response as the second.

The `error` object may optionally have a `code` property, which will be sent back to the user. Slurry Services use the same codes and status as HTTP, which are defined at [httpstatus.es](http://httpstatus.es). If a `code` is not defined, the it will default to a `500`, which translates to `Internal Server Error`. The helper method `job._userError(code, message)` is available to generate an error with a code.

```coffee
error = new Error("I'm a Teapot")
error.code = 418
callback(error)

# Using the helper method
callback(@_userError(418, "I'm a Teapot"))
```

If the `error` object is null, a `response` object is expected. The `response` object should validate against the complete responseSchema, including the `metadata`.

```coffee
callback(null, {
  metadata:
    code: 201
    status: http.STATUS_CODES[201]
  data:
    username: 'sqrtofsaturn'
    id: 1234
})
```

It is recommended that developers use existing NPM modules to interface with the target API. For example, the generated `job.coffee` uses the [github npm module](https://www.npmjs.com/package/github) to retrieve the events list instead of manually creating an HTTP request.

#### form.cson

`from.cson` defines how the form will be displayed to the user. Multiple form schemas can be defined for different message schema editors. It is recommended to nest the form schema under a key to target a specific form schema editor to make it easier to add support for additional editors in the future. The Octoblu Designer uses [Angular Schema Form](http://schemaform.io/) and the message handler expects the form schema to be nested under the `angular` key.

#### message.cson

`message.cson` defines the format all incoming messages must have in order to be processed by the job. Currently, messages that do not match the schema will still be allowed through to the Job, but that will likely change in the near future. A few additional properties will automatically be merged in to the message schema by the message handler before it's made available outside the Slurry Service.

* `x-form-schema.angular` Will point the form schema at the key `message.{MessageType}.angular`
* `x-response-schema` Will point the response schema to `{MessageType}`
* `properties.metadata` Will add `properties.metadata.jobType` as a required field that accepts only the MessageType name.

There is an additional property, `x-group-name`, that can be set to indicate which group a job belongs to. This is used in the Octoblu Designer's message type drop down to group different message types.

So a message schema for a job `list-events-by-user` that looks like this:

```coffee
{
  type: 'object'
  title: 'List Events by User'
  'x-group-name': 'User Events'
  required: ['metadata', 'data']
  properties:
    data:
      type: 'object'
      required: ['username']
      properties:
        username:
          type: 'string'
          title: 'Username'
          description: 'Github username or organization name'
}
```

Will end up like this:

```coffee
{
  type: 'object'
  title: 'List Events by User'
  'x-form-schema':
    angular: 'message.ListEventsByUser.angular'
  'x-group-name': 'User Events'
  'x-response-schema': 'ListEventsByUser'
  required: ['metadata', 'data']
  properties:
    metadata:
      type: 'object'
      required: ['jobType']
      properties:
        jobType:
          type: 'string'
          enum: ['ListEventsByUser']
          default: 'ListEventsByUser'
    data:
      type: 'object'
      required: ['username']
      properties:
        username:
          type: 'string'
          title: 'Username'
          description: 'Github username or organization name'
}
```

#### response.cson

`response.cson` defines the format of the response messages from the Slurry Service. Currently, the response schema isn't used for anything. However, we have big plans for this little guy, so don't leave him out! A few additional properties will automatically be merged in to the response schema by the message handler before it's made available outside the Slurry Service.

* `properties.metadata` Defines the the status and code of the response.

So a response schema for a job `list-events-by-user` that looks like this:

```coffee
{
  type: 'object'
  required: ['metadata', 'data']
  properties:
    data:
      type: 'object'
      required: ['username']
      properties:
        username:
          type: 'string'
          description: 'The github username that performed the event. (ex: "sqrtofsaturn")'
}
```

Will end up like this:

```coffee
{
  type: 'object'
  required: ['metadata', 'data']
  properties:
    metadata:
      type: 'object'
      required: ['status', 'code']
      properties:
        status:
          type: 'string'
        code:
          type: 'integer'
    data:
      type: 'object'
      required: ['username']
      properties:
        username:
          type: 'string'
          description: 'The github username that performed the event. (ex: "sqrtofsaturn")'
}
```
