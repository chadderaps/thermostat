debug = require('debug') 'dynamo-db'
AWS = require 'aws-sdk'
crypto = require 'crypto'

module.exports =
class DynamoDB

  DATA_TYPES : {
    'string': 'S'
    'number': 'N'
    'boolean': 'BOOL'
    'string list': 'SS'
    'number list': 'NS'
    'item': 'L'
    'object': 'M'
  }

  constructor: (params) ->

    dynamoParams = {}

    @putTimeout = params.putTimeout  ? 5000
    @backoff = {
      timeout: params.backkoffTimeout ? 50
      maxTimeout: params.backoffMaxTimeout ? @putTimeout
      count: 0
      active: false
    }

    debug @putTimeout

    AWS.config.update {region: params.region || 'us-east-2'}

    if params.endpoint?
      dynamoParams.endpoint = new AWS.Endpoint params.endpoint

    @db = new AWS.DynamoDB dynamoParams

    for table in params.tables || []
      @setTable table

    debug JSON.stringify @tables

    return

  setTable: (params) ->
    @tables = {} if not @tables?
    id = params.id

    @tables[id] = {
      name: params.name
      queue: []
      timeout: params?.timeout ? @putTimeout
      backoff: Object.assign {}, @backoff
      singleId: params.singleId ? false
      singleIdName: if params.singleId? then id else null
      keyGen: params.keyGen ? null
    }

    if @tables[id].timeout
      setInterval () => @_putMultiple id, @tables[id].queue, @tables[id].timeout

  exists: (tableId, callback) ->
    callback new Error('InvalidTableID'), {} if not @tables?[tableId]?
    @db.describeTable {TableName: @tables[tableId].name}, (err, data) =>
      if err?.code == 'ResourceNotFoundException'
        callback null, false
      else if err?
        callback err, false
      else
        callback null, true

  wait: (tableId, callback) ->
    callback new Error('InvalidTableID'), {} if not @tables?[tableId]?
    @db.waitFor 'tableExists', {TableName: @tables[tableId].name}, callback

  create: (tableId, params, callback = {}) ->

    if typeof params == 'function'
      callback = params
      params = {
        withDate: true
      }

    callback new Error('InvalidTableID'), {} if not @tables?[tableId]?

    if @tables[tableId].singleId?
      params.withDate = true


    tableParams = {
      TableName: @tables[tableId].name
      AttributeDefinitions: [
        {
          AttributeName: '_id'
          AttributeType: 'S'
        }
      ]
      KeySchema: [
        {
          AttributeName: '_id'
          KeyType: 'HASH'
        }
      ]
      ProvisionedThroughput: {
        ReadCapacityUnits: params.ReadCap || 1
        WriteCapacityUnits: params.WriteCap || 1
      }
    }

    if params.withDate?
      tableParams.AttributeDefinitions.push {
          AttributeName: '_date'
          AttributeType: 'N'
      }
      tableParams.KeySchema.push {
        AttributeName: '_date'
        KeyType: 'RANGE'
      }

    @db.createTable tableParams, (err, data) =>
      callback err, data

  list: (callback) ->
    @db.listTables (err, data) =>
      callback err, data.TableNames

  getItems: (tableId, callback) ->

    params = {
      TableName: @tables[tableId].name
    }

    @db.scan params, (err, data) =>
      return callback err if err
      items = []

      for item in data.Items
        items.push @_parseItem item

      callback null, items

  get: (tableId, key, callback) ->
    callback new Error('InvalidTableID'), {} if not @tables?[tableId]?

    if key instanceof Array
      search = key[1]
      key = key[0]

    params = {
      TableName: @tables[tableId].name
      Limit: 1
      Select: 'ALL_ATTRIBUTES'
      ScanIndexForward: true
      KeyConditionExpression: '#id = :id'
      ExpressionAttributeNames: {
        '#id' : '_id'
      }
      ExpressionAttributeValues: {
        ":id": {
          S: key
        }
      }
    }

    debug JSON.stringify params

    cb = ((params) =>
      @db.query params, (err, data) =>
        debug '------------------------------'
        debug JSON.stringify data
        item = data.Items[0]
        callback err, @_parseItem item
    ).bind @

    if @tables[tableId].keyGen?
      key = @tables[tableId].keyGen key, (newKey) =>
        params.ExpressionAttributeValues[':id'].S = newKey
        debug JSON.stringify params
        cb params
    else
      cb params

    return

  getLatest: (tableId, callback) ->
    callback new Error('InvalidTableID'), {} if not @tables?[tableId]?
    callback new Error('NotSingleIDTable'), {} if not @tables[tableId].singleId?

    params = {
      TableName: @tables[tableId].name
      Limit: 1
      Select: 'ALL_ATTRIBUTES'
      ScanIndexForward: false
      KeyConditionExpression: '#id = :id'
      ExpressionAttributeNames: {
        '#id' : '_id'
      }
      ExpressionAttributeValues: {
        ":id": {
          S: @tables[tableId].singleIdName
        }
      }
    }

    debug JSON.stringify params

    @db.query params, (err, data) =>
      debug '------------------------------'
      debug JSON.stringify data
      callback err, data


  _putWithBackoff: (tableId, params, callback) ->
    backoff = @tables[tableId].backoff

    nextTimeout = backoff.timeout * 2 ** backoff.count
    nextTimeout = backoff.maxTimeout if nextTimeout > backoff.maxTimeout

    backoff.count++

    nextTimeout *= Math.random()

    @db.batchWriteItem params, (err, data) =>
      debug data
      retry = false
      if err?
        if err.code != 'ProvisionedThroughputExceededException'
          callback err

      if data.UnprocessedItems.RequestItems?
        retry = true

      if retry
        debug "Retrying request"
        setTimeout (() => @putWithBackoff data.UnprocessedItems), nextTimeout
      else
        backoff.active = false
        callback null

  _putMultiple: (tableId, items) ->

    return if @tables[tableId].backoff.active
    return if @tables[tableId].queue.length == 0

    maxCount = 25
    @tables[tableId].backoff.active = true
    @tables[tableId].backoff.count = 0

    params = {
      RequestItems: {}
    }

    reqitems = []

    while items.length and reqitems.length <= maxCount
      item = items.shift()

      entry = {
        PutRequest: {
          Item: {}
        }
      }

      debug JSON.stringify item

      entry.PutRequest.Item = @_parseObject item

      reqitems.push entry

    params.RequestItems[@tables[tableId].name] = reqitems

    @_putWithBackoff tableId, params, (err) =>
      throw err if err

    return

  _putSingle: (tableId, item, id, date, callback) ->

    params = {
      TableName: @tables[tableId].name
      Item: {
        _id: {
          S: id
        }
        _date: {
          N: date.toString()
        }
      }
    }

    debug item

    parsedItem = @_parseObject item

    Object.assign params.Item, parsedItem

    debug params
    @db.putItem params, (err, data) =>
      throw err if err
      debug data
      callback err, @_parseItem params.Item

  _enqueue: (tableId, item, id, date, callback) ->
    item._date ?= date
    item._id = id
    @tables[tableId].queue.push item
    callback null, item

  put: (tableId, item, callback) ->
    callback new Error('InvalidTableID') if not @tables?[tableId]?

    cb = if @tables[tableId].timeout != 0 then @_enqueue.bind @ else @_putSingle.bind @

    if @tables[tableId].singleId
      cb tableId, item, @tables[tableId].singleIdName, Date.now(), callback
    else if @tables[tableId].keyGen?
      @tables[tableId].keyGen item.id, (id) =>
        cb tableId, item, id, Date.now(), callback
    else
      @_uuid tableId, (id, date) =>
        cb tableId, item, id, date, callback if id? and date?

  _scan: (tableId, callback) ->
    params = {
      TableName: @tables[tableId].name
    }
    @db.scan params, (err, data) =>
      debug 'Finished the scan'
      debug JSON.stringify data
      item = @_parseItem data.Items[0]
      debug item
      callback err, item

  update: (tableId, item, callback) ->
    callback new Error('InvalidTableID') if not @tables?[tableId]?

    params = {
      TableName: @tables[tableId].name
      ReturnValues: 'ALL_NEW'
      ExpressionAttributeNames: {}
      ExpressionAttributeValues: {}
      Key: {}
    }

    debug 'Update'

    @_scan tableId, (err, orig) =>
      throw err if err

      if not orig._id?
        @put tableId, item, callback
      else
        debug orig
        params.Key = {
          _id: {
            S: orig._id
          }
          _date: {
            N: orig._date.toString()
          }
        }

        Exp = 'SET '
        prepend = ''
        ExpNames = {}
        ExpVals = {}

        for k,v of item
          name = '#' + k.replace(' ', '_')
          val = ':' + k.replace(' ', '_')
          ExpNames[name] = k
          ExpVals[val] = @_parseValue v
          Exp += "#{prepend}#{name} = #{val}"
          prepend=','

        params.ExpressionAttributeNames = ExpNames
        params.ExpressionAttributeValues = ExpVals
        params.UpdateExpression = Exp

        @db.updateItem params, (err, data) =>
          throw err if err
          debug 'Updated the table '
          debug data


  _uuid: (tableId, callback, retries=10) ->
    new_id = crypto.randomBytes(16).toString 'base64'
    date = Date.now()
    debug "New ID is #{new_id}"
    params = {
      Key: {
        "_id": {S: new_id}
        "_date": {N: date.toString()}
      }
      TableName: @tables[tableId].name
    }
    @db.getItem params, ((err, data) =>
      if err
        debug "UUID Get ID Error"
        debug params
        debug err
        callback null, null
      else if (data.length)
        debug 'New ID Found, try again'
        @_uuid callback, retries-1 if retries > 0
        callback null, null if retries <= 0
      else
        callback new_id, date
        ).bind @

  _getDataType: (data) ->
    type = @DATA_TYPES[typeof data]

    return type if type?

    aVal = data[Object.keys(data)[0]]

    type = @DATA_TYPES[typeof aVal + ' list']

    return type if type?

    throw new Error 'Invalid type for #{data}'

  _parseItem: (item) ->

    obj = {}
    for k,v of item
      debug v
      if v.N
        newV = Number(v.N)
      else
        newV = v[Object.keys(v)[0]]

      if v.M
        newV = @_parseItem newV

      obj[k] = newV
      debug "#{newV} is #{typeof newV}"

    return obj

  _parseValue: (v) ->
      type = @_getDataType v
      v = v.toString() if type is 'N'
      obj = {}
      v = @_parseObject v if type is 'M'
      obj[type] = v
      return obj


  _parseObject: (obj) ->

    parsed = {}

    for k,v of obj
      parsed[k] = @_parseValue(v)

    return parsed
