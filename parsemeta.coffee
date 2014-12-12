module.exports = (str) ->
  ok = false
  meta = {}
  for line in str.split('\n')
    if line.indexOf(':') isnt -1
      parts = line.split(':')
      key = parts[0].trim()
      value = parts[1].trim()
      if key and value
        ok = true
        meta[key] = value
    else if line.indexOf(' ') is -1
      line = line.trim()
      meta[line] = true if line

  if ok
    return meta
