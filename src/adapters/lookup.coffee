##  WARNING:
##  ========
##  This file was compiled from a macro.
##  Do not edit it directly.

{create, createObject, createArray} = require '../specHelper'

# Returns value
# Used by getters & reference indexer
# Does not dereference the final item if getRef is truthy
lookup = (path, data, getRef) ->

  curr = data
  props = path.split '.'
  path = ''
  data.$remainder = ''
  i = 0
  len = props.length

  while i < len
    prop = props[i++]
    curr = curr[prop]


    # The absolute path traversed so far
    path = if path then path + '.' + prop else prop

    break unless curr?

    if curr.$r
      break if getRef && i == len

      refObj = lookup curr.$r, data
      dereffedPath = if data.$remainder then "#{data.$path}.#{data.$remainder}" else data.$path

      if key = curr.$k
        if Array.isArray keyObj = lookup key, data
          if i < len
            prop = keyObj[props[i++]]
            path = dereffedPath + '.' + prop
            curr = lookup dereffedPath, data
          else
            curr = (lookup dereffedPath + '.' + index, data for index in keyObj)
        else
          dereffedPath += '.' + keyObj
          curr = lookup dereffedPath, data
          path = dereffedPath unless i == len
      else
        curr = refObj
        path = dereffedPath unless i == len
    
      if `curr == null`
        # Return if the reference points to nothing
        data.$remainder = props.slice(i).join '.'
        break
    

  data.$path = path
  return curr

# Returns [value, {ver}]
# Used by getters
lookupWithVersion = (path, data, vers) ->

  curr = data
  currVer = vers
  props = path.split '.'
  path = ''
  data.$remainder = ''
  i = 0
  len = props.length

  while i < len
    prop = props[i++]
    curr = curr[prop]

    currVer = currVer[prop] || currVer

    # The absolute path traversed so far
    path = if path then path + '.' + prop else prop

    break unless curr?

    if curr.$r

      [refObj, currVer] = lookupWithVersion curr.$r, data, vers
      dereffedPath = if data.$remainder then "#{data.$path}.#{data.$remainder}" else data.$path

      if key = curr.$k
        if Array.isArray keyObj = lookup key, data
          if i < len
            prop = keyObj[props[i++]]
            path = dereffedPath + '.' + prop
            [curr, currVer] = lookupWithVersion path, data, vers
          else
            curr = (lookup dereffedPath + '.' + index, data for index in keyObj)
        else
          dereffedPath += '.' + keyObj
          curr = lookup dereffedPath, data
          path = dereffedPath unless i == len
      else
        curr = refObj
        path = dereffedPath unless i == len
    
      if `curr == null`
        # Return if the reference points to nothing
        data.$remainder = props.slice(i).join '.'
        break
    

  data.$path = path
  return [curr, currVer]

# Returns value
# Used by reference indexer
lookupAddPath = (path, data, speculative, pathType) ->

  curr = data
  props = path.split '.'
  path = ''
  data.$remainder = ''
  i = 0
  len = props.length

  while i < len
    prop = props[i++]
    parent = curr
    curr = curr[prop]


    # The absolute path traversed so far
    path = if path then path + '.' + prop else prop

    # Create empty objects implied by the path
    if curr?
      curr = parent[prop] = create curr  if speculative && typeof curr is 'object'
    else
      unless pathType
        data.$remainder = props.slice(i).join '.'
        break
      # If pathType is truthy, create empty parent objects implied by path
      curr = parent[prop] = if speculative
          if pathType is 'array' && i == len then createArray() else createObject()
        else
          if pathType is 'array' && i == len then [] else {}

    if curr.$r

      refObj = lookup curr.$r, data
      dereffedPath = if data.$remainder then "#{data.$path}.#{data.$remainder}" else data.$path

      if key = curr.$k
        if Array.isArray keyObj = lookup key, data
          if i < len
            prop = keyObj[props[i++]]
            path = dereffedPath + '.' + prop
            curr = lookup dereffedPath, data
          else
            curr = (lookup dereffedPath + '.' + index, data for index in keyObj)
        else
          dereffedPath += '.' + keyObj
          curr = lookup dereffedPath, data
          path = dereffedPath unless i == len
      else
        curr = refObj
        path = dereffedPath unless i == len
    
      if `curr == null` && !pathType
        # Return if the reference points to nothing
        data.$remainder = props.slice(i).join '.'
        break
    

  data.$path = path
  return curr

# Returns [value, {ver}, parent, prop]
# Used by setters & delete
lookupSetVersion = (path, data, vers, setVer, pathType) ->
  speculative = !setVer

  curr = data
  currVer = vers
  currVer.ver = setVer  if setVer
  props = path.split '.'
  path = ''
  data.$remainder = ''
  i = 0
  len = props.length

  while i < len
    prop = props[i++]
    parent = curr
    curr = curr[prop]

    currVer = currVer[prop] || if pathType && setVer then currVer[prop] = {} else currVer

    # The absolute path traversed so far
    path = if path then path + '.' + prop else prop

    # Create empty objects implied by the path
    if curr?
      curr = parent[prop] = create curr  if speculative && typeof curr is 'object'
    else
      unless pathType
        data.$remainder = props.slice(i).join '.'
        break
      # If pathType is truthy, create empty parent objects implied by path
      curr = parent[prop] = if speculative
          if pathType is 'array' && i == len then createArray() else createObject()
        else
          if pathType is 'array' && i == len then [] else {}

    if curr.$r

      [refObj, currVer] = lookupSetVersion curr.$r, data, vers, setVer, pathType
      dereffedPath = if data.$remainder then "#{data.$path}.#{data.$remainder}" else data.$path

      if key = curr.$k
        if Array.isArray keyObj = lookup key, data
          if i < len
            prop = keyObj[props[i++]]
            path = dereffedPath + '.' + prop
            [curr, currVer] = lookupSetVersion path, data, vers, setVer, pathType
          else
            curr = (lookup dereffedPath + '.' + index, data for index in keyObj)
        else
          dereffedPath += '.' + keyObj
          curr = lookup dereffedPath, data
          path = dereffedPath unless i == len
      else
        curr = refObj
        path = dereffedPath unless i == len
    
      if `curr == null` && !pathType
        # Return if the reference points to nothing
        data.$remainder = props.slice(i).join '.'
        break
    
    else
      currVer.ver = setVer  if setVer

  data.$path = path
  return [curr, currVer, parent, prop]


module.exports = {lookup, lookupWithVersion, lookupAddPath, lookupSetVersion}
