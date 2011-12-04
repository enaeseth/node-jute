bigint = require "bigint"
sixty_four_bits = bigint("FFFFFFFFFFFFFFFF", 16)

exports.Type = class Type
  constructor: (@name, @normalize) ->

  toString: ->
    "<Type #{@name}>"

exports.VectorType = class VectorType extends Type
  constructor: (name, @elementType) ->
    super name, (val) => @elementType.normalize(el) for el in val

exports.RecordType = class RecordType
  constructor: (name, fields) ->
    throw new Error("RecordType name required") unless name?
    throw new Error("RecordType fields required") unless fields?

    class Record
      constructor: (vals) ->
        if vals?
          for field, type of Record.fields
            if field of vals
              this[field] = type.normalize(vals[field])

    Record.name = name
    Record.fields = fields
    Record.normalize = (val) ->
      if val instanceof Record
        val
      else
        new Record(val)

    return Record

exports.byte = new Type "byte", (val) -> val & 0xFF
exports.boolean = new Type "boolean", Boolean
exports.int = new Type "int", (val) -> Number(val) & 0xFFFFFFFF
exports.long = new Type "long", (val) -> bigint(val).and(sixty_four_bits)
exports.float = new Type "float", Number
exports.double = new Type "double", Number
exports.ustring = new Type "ustring", (val) ->
  if val?
    String(val)
  else
    null
exports.buffer = new Type "buffer", (val) ->
  if val instanceof Buffer
    val
  else if val?
    # encode the string value as UTF-8 in a new Buffer
    new Buffer(String(val))
  else
    null

exports.vector = (type) ->
  name = type.name ? "?"
  new VectorType "vector<#{name}>", type
