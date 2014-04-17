->
  taistApi = null

  start = (_taistApi) ->
    taistApi = _taistApi
    taistApi.hash.useHashchangeEvent = false

    buttonsBar.renderOnCurrentTaskChange()
    filtersPanel.renderOnFiltersAppear()

  states =
    initial:
      next: ['onApproval']
      visibleTo: 'owner'

    onApproval:
      next: ['approved', 'declined']
      buttonTitle: 'Send for approval'
      title: 'OnApproval'
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

  buttonsBar =
    _containerSelector: '.wspace-task-widgets-title-view'
    _buttonsToolbarId: 'wrike-taist-toolbar'
    _originalToolbarSelector: '.wspace-task-settings-bar'

    renderOnCurrentTaskChange: ->
      setTaskIfNotNull = (task) =>
        if task?
          @_setTask task
      wrikeUtils.onCurrentTaskChange setTaskIfNotNull
      wrikeUtils.onCurrentTaskSave setTaskIfNotNull

    _setTask: (task) ->
      @_cleanButtons()

      currentState = extractStateFromInput @_getTitleInput()

      if @_stateIsVisibleToMe task, currentState
        @_renderButtons currentState

    _cleanButtons: ->
      ($ '#' + @_buttonsToolbarId).remove()

    _stateIsVisibleToMe: (task, state) -> ((wrikeUtils.myTaskRoles task).indexOf state.visibleTo) > -1

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
      applyStateToInput state, @_getTitleInput()
      state.action?()

    _getTitleInput: -> $ "#{@_containerSelector} textarea"

  extractStateFromInput = (input) ->
    lowerCasedInputText = input.val().toLowerCase()
    for stateName, state of states
      if (lowerCasedInputText.indexOf getNormalizedStatePrefix state) >= 0
        return state

    return states.initial

  applyStateToInput = (state, input) ->
    currentText = input.val()
    window.curInput = input
    input.val (applyStateToText state, currentText)

    # Emulate pressing enter on task title input to trigger input change event
    input.focus()
    $.event.trigger
      type: 'keypress'
      which: 13
    input.blur()

  getNormalizedStatePrefix = (state) -> $.trim (getTitlePrefix state).toLowerCase()

  applyStateToText = (statetoApply, currentText) ->
    for stateName, state of states
      for removedPrefix in [(getTitlePrefix state), (getNormalizedStatePrefix state)]
        currentText = currentText.replace removedPrefix, ''

    if statetoApply?
      currentText = (getTitlePrefix statetoApply) + currentText

    return currentText

  getTitlePrefix = (state) -> "[#{state.title}] "

  filtersPanel =
    _filtersPanelSelector: '.wspace-folder-filterpanel-body'
    _filterGroupClass: "wspace-folder-filterpanel-filterpane wspace-tree-branch-root"
    _filtersContainerClass: 'wspace-tree-branch'
    _filterSelectedClass: 'x-btn-pressed'
    _filtersFoldButtonClass: 'wspace-tree-foldButton'
    _filtersFoldClass: 'wspace-tree-folded'
    _searchFieldSelector: '.wspace-folder-mainbar .wrike-field-search input'

    _filters: null

    renderOnFiltersAppear: ->
      taistApi.wait.elementRender @_filtersPanelSelector, (filtersPanel) =>
        filtersContainer = @_renderFiltersContainer filtersPanel
        @_renderFilters filtersContainer

        @_setCurrentState()

    _renderFiltersContainer: (filtersPanel) ->
      filtersGroup = @_createFiltersGroupDom()

      previousFiltersGroup = filtersPanel.find(@_getSelectorFromClass @_filterGroupClass).last()
      previousFiltersGroup.after filtersGroup

      foldButton = filtersGroup.find @_getSelectorFromClass @_filtersFoldButtonClass
      foldButton.click =>
        filtersGroup.toggleClass @_filtersFoldClass

      return filtersGroup.find (@_getSelectorFromClass @_filtersContainerClass)

    _renderFilters: (filtersContainer) ->
      @_filters = []
      for _, state of states
        if state.title?
          filter = @_renderFilter state

          @_filters.push filter
          filtersContainer.append filter

    _setCurrentState: ->
      @_updateFilters (extractStateFromInput @_getSearchField()), false

    _createFiltersGroupDom: -> $ """
<div class="#{@_filterGroupClass}">
	<div class="wspace-tree-plate">
		<div class="#{@_filtersFoldButtonClass}"></div>
		<div class="wspace-tree-title-root">Approval</div>
	</div>
	<div class="#{@_filtersContainerClass}">
	</div>
</div>
"""
    _getSelectorFromClass: (classString) ->
      singleSelectorsArray = (("." + singleClass) for singleClass in classString.split ' ')
      return singleSelectorsArray.join()

    _renderFilter: (state, filtersPanel) ->
      filter = @_createFilterDom state.title

      filter.click =>
        targetState =
          if filter.hasClass @_filterSelectedClass
            null
          else
            state

        @_updateFilters targetState, true

        return false

    _createFilterDom: (filterTitle) -> $ """<a class="wrike-button-checkbox x-btn-noicon" href="#" style="width: auto;">#{filterTitle}</a>"""

    _updateFilters: (state, needUpdateSearchField) ->
      for filter in @_filters
        filter.toggleClass @_filterSelectedClass, state?.title is filter.text()

      if needUpdateSearchField
        applyStateToInput state, @_getSearchField()

    _getSearchField: -> $ @_searchFieldSelector

  wrikeUtils =
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
      taistApi.wait.change (=> @currentTask()), (task) ->
        if task?
          taistApi.wait.once (-> task.data.title?), ->
            callback task

    onCurrentTaskSave: (callback) ->
      taistApi.aspect.after $wrike.record.Base.prototype, 'getChanges', ->
        if @ is wrikeUtils.currentTask()
          callback @

  {start}
