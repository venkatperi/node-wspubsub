#see https://gist.github.com/reversepanda/5814547

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc