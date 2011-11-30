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

  fixed = (bytes) ->
    ensure bytes
    advance bytes

  append = (type, value) ->
    if type.fields # record type
      for name, elementType of type.fields
        append elementType, elementType.normalize(value[name])
    else if type is types.byte
      buffer.writeUInt8 value, fixed(1)
    else if type is types.boolean
      buffer.writeUInt8 (if value then 1 else 0), fixed(1)
    else if type is types.int
      buffer.writeInt32BE value, fixed(4)
    else if type is types.long
      buffer.fill 0, offset, offset + 8
      value.toBuffer().copy(buffer, fixed(8))
    else if type is types.float
      buffer.writeFloatBE value, fixed(4)
    else if type is types.double
      buffer.writeDoubleBE value, fixed(8)
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

      buffer.writeInt32BE bytesWritten, fixed(4)
      advance bytesWritten if bytesWritten > 0
    else if type is types.buffer
      if value?
        ensure value.length
        buffer.writeInt32BE value.length, fixed(4)
        value.copy(buffer, fixed(value.length))
      else
        buffer.writeInt32BE -1, fixed(4)
    else if type instanceof types.VectorType
      if value?
        buffer.writeInt32BE value.length, fixed(4)
        for element in value
          append type.elementType, type.elementType.normalize(element)
      else
        buffer.writeInt32BE -1, fixed(4)

  append record.constructor, record

  buffer.length = offset
  buffer
