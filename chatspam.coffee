app = angular.module('chatspam', [])

app.controller 'ChatspamController', ($scope) ->
  $scope.items = []
  $scope.config = '// Your configuration will appear here after pressing "Generate"'
  $scope.bind = ''

  newItem = (message='') ->
    message: message
    focus: true

  random_name = ->
    Math.floor((1 + Math.random()) * 0x100000000)
        .toString(16)
        .substring(1)

  say_alias_name = (name, index) ->
    name + '_' + index

  act_alias_name = (say_alias) ->
    say_alias + '_act'

  generate_say_alias = (say_alias, message) ->
    'alias "' + say_alias + '" "say ' + message + '"'

  generate_act_alias = (name, act_alias, say_alias, next) ->
    'alias "' + act_alias + '" "' + say_alias + '; alias ' + name + ' ' + next + '"'

  $scope.addItem = (message) ->
    $scope.items.push(newItem(message))

  $scope.generate = ->
    # The config works like this:
    #  - Each chat message is assigned a unique ID, by creating an alias of "say XXXX" for each message
    #  - A generic "send message" alias is created, which calls the first "act alias"
    #  - Each "act alias" runs a "chat message" alias, then rebinds the generic "send message" alias to the next "act alias" in the list

    name = random_name()

    aliases = []
    say_aliases = []
    act_aliases = []

    # Generate the stand-alone aliases which simply regurgitate their chat message
    # This step simply gives each chat message an ID we control.
    _.each $scope.items, (item, index) ->
      say_alias = say_alias_name(name, index)
      say_aliases.push(say_alias)
      aliases.push(generate_say_alias(say_alias, item.message))

    # Generate the aliases which send a chat message and rebind the
    _.each say_aliases, (say_alias, index) ->
      act_alias = act_alias_name(say_alias)
      act_aliases.push(act_alias)

      if index == say_aliases.length - 1
        next = act_aliases[0]
      else
        next = act_alias_name(say_aliases[index + 1])

      aliases.push(generate_act_alias(name, act_alias, say_alias, next))

    first_alias = 'alias "' + name + '" "' + act_aliases[0] + '"'
    bind = 'bind "' + $scope.bind + '" "' + name + '"'
    config = [aliases.join(';\n'), first_alias, bind]
    $scope.config = config.join(';\n')

  do $scope.addItem

# Handles the list of messages, including advancing to the next message
app.directive 'messages', ->
  ($scope) ->
    $scope.$on 'enter', (evt, data) ->
      $scope.$apply ->
        if data.index == $scope.items.length - 1
          do $scope.addItem
        else
          $scope.items[data.index + 1].focus = true


# Handles a single message
app.directive 'message', ->
  restrict: 'A'
  scope:
    item: '='
    index: '='
  controller: ($scope, $element) ->
    RETURN = 13

    $scope.$watch 'item.focus', ->
      do $element[0].focus
      $scope.item.focus = false

    $element.on 'keypress', (evt) ->
      if evt.keyCode == RETURN
        $scope.$emit 'enter',
          item: $scope.item
          index: $scope.index
