bigint = require "bigint"
util = require "util"
types = require "../types"

exports.serialize = (record, buffer, offset) ->
  buffer ?= new Buffer(1)
  offset ?= 0

  fields = record.constructor.fields
  if not fields?
    throw new TypeError("#{util.inspect(record)}# doesn't look like a Record")

  grow = ->
    resized = new Buffer(buffer.length * 2)
    buffer.copy(resized)
    buffer = resized

  ensure = (bytes) ->
    while offset + bytes >= buffer.length
      grow()

  advance = (bytes) ->
    [currentOffset, offset] = [offset, offset + bytes]
    currentOffset

  append = (type, value) ->
    if type.fields # record type
      for name, elementType of type.fields
        append elementType, elementType.normalize(value[name])
    else if type is types.byte
      ensure 1
      buffer.writeUInt8 value, advance(1)
    else if type is types.boolean
      ensure 1
      buffer.writeUInt8 (if value then 1 else 0), advance(1)
    else if type is types.int
      ensure 4
      buffer.writeInt32BE value, advance(4)
    else if type is types.long
      ensure 8
      buffer.fill 0, offset, offset + 8
      value.toBuffer(size: 8).copy(buffer, advance(8))
    else if type is types.float
      ensure 4
      buffer.writeFloatBE value, advance(4)
    else if type is types.double
      ensure 8
      buffer.writeDoubleBE value, advance(8)
    else if type is types.ustring
      if value?
        ensure 4
        bodyOffset = offset + 4 # skip length field

        # Optimistically assume the string will fit
        bytesWritten = buffer.write value, bodyOffset
        charsWritten = Buffer._charsWritten

        # But if it doesn't, grow the buffer and do it right
        if Buffer._charsWritten < value.length
          ensure Buffer.byteLength(value)
          bytesWritten = buffer.write value, bodyOffset
      else
        bytesWritten = -1

      ensure 4
      buffer.writeInt32BE bytesWritten, advance(4)
      advance bytesWritten if bytesWritten > 0
    else if type is types.buffer
      if value?
        ensure value.length + 4
        buffer.writeInt32BE value.length, advance(4)
        value.copy buffer, advance(value.length)
      else
        ensure 4
        buffer.writeInt32BE -1, advance(4)
    else if type instanceof types.VectorType
      if value?
        ensure 4
        buffer.writeInt32BE value.length, advance(4)
        for element in value
          append type.elementType, type.elementType.normalize(element)
      else
        ensure 4
        buffer.writeInt32BE -1, advance(4)

  append record.constructor, record

  buffer.slice(0, offset)

exports.deserialize = (type, buffer, offset) ->
  offset ?= 0
  fields = type.fields
  longBuffer = null

  advance = (bytes) ->
    [currentOffset, offset] = [offset, offset + bytes]
    currentOffset

  unpack = (type) ->
    readWithLength = (reader) ->
      length = buffer.readInt32BE(advance(4))
      if length < 0
        null
      else
        reader(length)

    if type.fields # record type
      record = new type

      for name, elementType of type.fields
        record[name] = unpack(elementType)

      record
    else if type is types.byte
      buffer.readUInt8(advance(1))
    else if type is types.boolean
      !!buffer.readUInt8(advance(1))
    else if type is types.int
      buffer.readInt32BE(advance(4))
    else if type is types.long
      longBuffer ?= new Buffer(8)
      start = advance(8)
      buffer.copy(longBuffer, 0, start, offset)
      bigint.fromBuffer(longBuffer, size: 8)
    else if type is types.float
      buffer.readFloatBE(advance(4))
    else if type is types.double
      buffer.readDoubleBE(advance(8))
    else if type is types.ustring
      readWithLength (length) ->
        start = advance(length)
        buffer.toString("utf8", start, offset)
    else if type is types.buffer
      readWithLength (length) ->
        valueBuffer = new Buffer(length)
        start = advance(length)
        buffer.copy(valueBuffer, 0, start, offset)
        valueBuffer
    else if type instanceof types.VectorType
      readWithLength (length) ->
        unpack(type.elementType) for i in [0...length]
    else
      throw new Error("Unknown type: #{util.inspect(type)}")

  unpack type
