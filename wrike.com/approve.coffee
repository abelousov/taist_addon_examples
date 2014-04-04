->
  taistApi = null

  start = (_taistApi) ->
    taistApi = _taistApi

    (new WrikeTaskApprover()).renderOnCurrentTaskChange()
  #    (new WrikeTaskFilters()).renderOnFiltersAppear()

  states =
    initial:
      next: ['onApproval']
      visibleTo: 'owner'
    onApproval:
      next: ['approved', 'declined']
      buttonTitle: 'Send for approval'
      title: 'On Approval'
      visibleTo: 'author'
    approved:
      buttonTitle: 'Approve'
      title: 'Approved'
      visibleTo: 'owner'
      action: ->
        #emulate pressing on "complete" checkbox
        ($ '.wspace-task-widgets-status-view-checktip .check-wrap').click()
    declined:
      next: ['onApproval']
      title: 'Declined'
      buttonTitle: 'Decline'
      visibleTo: 'owner'

  class WrikeTaskApprover
    _containerSelector: '.wspace-task-widgets-title-view'
    _buttonsToolbarId: 'wrike-taist-toolbar'
    _originalToolbarSelector: '.wspace-task-settings-bar'

    renderOnCurrentTaskChange: ->
      setTaskIfNotNull = (task) =>
        if task?
          @_setTask task
      taistWrike.onCurrentTaskChange setTaskIfNotNull
      taistWrike.onCurrentTaskSave setTaskIfNotNull

    _setTask: (task) ->
      window.curTask = task
      taistApi.log 'current task: ', task
      @_cleanButtons()

      currentState = @_defineStateByTask task

      if @_stateIsVisibleToMe task, currentState
        @_renderButtons currentState

    _cleanButtons: ->
      ($ '#' + @_buttonsToolbarId).remove()

    _defineStateByTask: (task) ->
      taskTitle = task.data['title']
      for stateName, state of states
        if (taskTitle.indexOf (@_getTitlePrefix state)) >= 0
          return state

      return states.initial

    _stateIsVisibleToMe: (task, state) -> ((taistWrike.myTaskRoles task).indexOf state.visibleTo) > -1

    _renderButtonsToolbar: ->
      originalToolbar = $ @_originalToolbarSelector
      buttonsToolbar = (originalToolbar).clone()
      buttonsToolbar.empty()
      buttonsToolbar.attr 'id', @_buttonsToolbarId
      originalToolbar.after buttonsToolbar

      return buttonsToolbar

    _renderButtons: (state) ->
      buttonsToolbar = @_renderButtonsToolbar()
      if state.next?
        for nextStateName in state.next
          nextStateButton = @_createStateButton nextStateName
          buttonsToolbar.append nextStateButton

    _createStateButton: (stateName) ->
      state = states[stateName]
      button = $ '<a></a>',
        "class": "wspace-task-settings-button taist-wrike-approval-button"
        text: state.buttonTitle
        id: 'taist-wrike-approval-' + stateName
        click: =>
          @_applyStateToCurrentTask state
          false

    _applyStateToCurrentTask: (state) ->
      @_updateTaskTitle state
      state.action?()

    _updateTaskTitle: (state) ->
      titleInput = $ "#{@_containerSelector} textarea"
      currentTitle = titleInput.val()
      titleInput.val @_applyStateToTitle currentTitle, state

      # Emulate pressing enter on task title input to trigger save
      titleInput.focus()
      $.event.trigger
        type: 'keypress'
        which: 13
      titleInput.blur()

    _applyStateToTitle: (currentTitle, newState) ->
      for stateName, state of states
        currentTitle = currentTitle.replace (@_getTitlePrefix state), ''

      currentTitle = (@_getTitlePrefix newState) + currentTitle

      return currentTitle

    _getTitlePrefix: (state) -> "[#{state.title}] "

  class WrikeTaskFilters
    filter: 'All'
    cfg:
      flagTemplate: '<a class="wrike-button-checkbox x-btn-noicon" href="#"></a>'
      taistFiltersContainerId: 'wrike-taist-approval-filters'
      flagsOuterContainerSelector: '.type-selector'
      flagsInnerContainerSelector: '.x-column'
      flagCheckedClass: 'x-btn-pressed'
      streamTaskSelector: '.stream-task-entry'
      streamViewButtonSelector: '.wspace_header_buttonStreamView'

    renderOnFiltersAppear: ->
      #TODO: рендерить при нужном хэше
      if window.location.hash.match(/stream/)
        @renderFlags()
        @filterTasks()

    renderFlags: ->
      if $('#' + @cfg.taistFiltersContainerId).length
        return
      originalFlags = $ @cfg.flagsOuterContainerSelector
      flags = originalFlags.clone()
      flags.attr 'id', @cfg.taistFiltersContainerId
      flagsContainer = flags.find(@cfg.flagsInnerContainerSelector)
      flagsContainer.empty()
      originalFlags.after flags
      self = @
      for _, state of states
        flag = $(self.cfg.flagTemplate)
        flag.text state.titleTag or 'All'
        flagsContainer.append flag
        if @filter is flag.text()
          flag.addClass(self.cfg.flagCheckedClass)
        flag.on 'click', ->
          flagsContainer.find('a').
          removeClass(self.cfg.flagCheckedClass)
          $(@).addClass(self.cfg.flagCheckedClass)
          self.filter = $(@).text()
          self.filterTasks()
          false

    filterTasks: ->
      #TODO: add our filter to current filter
      $(@cfg.streamTaskSelector).each (i, element) =>
        console.log 'filter tasks here'

  window.taistWrike = taistWrike =
    me: -> $wrike.user.getUid()

    myTaskRoles: (task) ->
      roleConditions =
        owner: => task.data['responsibleList'].indexOf(@me()) >= 0
        author: => (task.get 'author') is @me()

      return (role for role,condition of roleConditions when condition())

    currentTaskView: ->
      taskViewId = $('.wspace-task-view').attr 'id'
      if taskViewId?
        window.Ext.ComponentMgr.get taskViewId

    currentTask: ->
      @currentTaskView()?['record']

    onCurrentTaskChange: (callback) ->
      callbackAfterTaskLoads = (task) ->
        if task?
          taistApi.wait.once (-> task.data.title?), ->
            callback task

      taistApi.wait.change (=> @currentTask()), callbackAfterTaskLoads

      callbackAfterTaskLoads @currentTask()

    onCurrentTaskSave: (callback) ->
      taistApi.aspect.after $wrike.record.Base.prototype, 'getChanges', ->
        if @ is taistWrike.currentTask()
          callback @

  {start}
