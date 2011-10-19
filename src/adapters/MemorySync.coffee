##  WARNING:
##  ========
##  This file was compiled from a macro.
##  Do not edit it directly.

{lookup, lookupWithVersion, lookupAddPath, lookupSetVersion} = require './lookup'
{clone: specClone} = require '../specHelper'
{array: arrayMutators} = require '../mutators'

MemorySync = module.exports = ->
  @_data = world: {}  # maps path -> val
  @_vers = ver: 0  # maps path -> ver
  return

MemorySync:: =
  version: (path, data) ->
    if path then lookupWithVersion(path, data || @_data, @_vers)[1].ver else @_vers.ver

  get: (path, data) ->
    data ||= @_data
    if path then lookup(path, data) else data.world

  getWithVersion: (path, data) ->
    data ||= @_data
    if path
      [obj, currVer] = lookupWithVersion path, data, @_vers
      return [obj, currVer.ver]
    else
      return [data.world, @_vers.ver]

  # Used by RefHelper
  getRef: (path, data) ->
    lookup path, data || @_data, true

  # Used by RefHelper
  getAddPath: (path, data, ver, pathType) ->
    lookupAddPath path, data || @_data, !ver, pathType

  set: (path, value, ver, data) ->
    {1: parent, 2: prop} = lookupSetVersion path, data || @_data, @_vers, ver, 'object'
    return parent[prop] = value

  del: (path, ver, data) ->
    data ||= @_data
    [obj, parent, prop] = lookupSetVersion path, data, @_vers, ver
    if ver
      delete parent[prop]
      return obj
    # If speculatiave, replace the parent object with a clone that
    # has the desired item deleted
    return obj unless parent
    if ~(index = path.lastIndexOf '.')
      parentPath = path.substr 0, index
      [parent, grandparent, parentProp] =
        lookupSetVersion parentPath, data, @_vers, ver
    else
      parent = data.world
      grandparent = data
      parentProp = 'world'
    parentClone = specClone parent
    delete parentClone[prop]
    grandparent[parentProp] = parentClone
    return obj

for method, {numArgs, outOfBounds, fn} of arrayMutators
  do (method, numArgs, outOfBounds, fn) ->
    MemorySync::[method] = switch numArgs
      when 0 then (path, ver, data) ->
        [arr] = lookupSetVersion path, data || @_data, @_vers, ver, 'array'
        throw new Error 'Not an Array' unless Array.isArray arr
        throw new Error 'Out of Bounds' if outOfBounds? arr
        return if fn then fn arr else arr[method]()
      when 1 then (path, arg0, ver, data) ->
        [arr] = lookupSetVersion path, data || @_data, @_vers, ver, 'array'
        throw new Error 'Not an Array' unless Array.isArray arr
        throw new Error 'Out of Bounds' if outOfBounds? arr, arg0
        return if fn then fn arr, arg0 else arr[method] arg0
      when 2 then (path, arg0, arg1, ver, data) ->
        [arr] = lookupSetVersion path, data || @_data, @_vers, ver, 'array'
        throw new Error 'Not an Array' unless Array.isArray arr
        throw new Error 'Out of Bounds' if outOfBounds? arr, arg0, arg1
        return if fn then fn arr, arg0, arg1 else arr[method] arg0, arg1
      else (path, args..., ver, data) ->
        [arr] = lookupSetVersion path, data || @_data, @_vers, ver, 'array'
        throw new Error 'Not an Array' unless Array.isArray arr
        throw new Error 'Out of Bounds' if outOfBounds? arr, args...
        return if fn then fn arr, args... else arr[method] args...

