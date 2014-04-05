->
  taistApi = null

  start = (_taistApi) ->
    taistApi = _taistApi
    taistApi.hash.useHashchangeEvent = false

    approver.renderOnCurrentTaskChange()
    allFilters.renderOnFiltersAppear()

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

  approver =
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
      @_cleanButtons()

      currentState = extractStateFromInput @_getTitleInput()

      if @_stateIsVisibleToMe task, currentState
        @_renderButtons currentState

    _cleanButtons: ->
      ($ '#' + @_buttonsToolbarId).remove()

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
      applyStateToInput state, @_getTitleInput()
      state.action?()

    _getTitleInput: -> $ "#{@_containerSelector} textarea"

  extractStateFromInput = (input) ->
    for stateName, state of states
      if (input.val().indexOf (getTitlePrefix state)) >= 0
        return state

    return states.initial


  applyStateToInput = (state, input) ->
    currentText = input.val()
    input.val applyStateToText state, currentText

    # Emulate pressing enter on task title input to trigger input change event
    input.focus()
    $.event.trigger
      type: 'keypress'
      which: 13
    input.blur()

  applyStateToText = (statetoApply, currentText) ->
    for stateName, state of states
      currentText = currentText.replace (getTitlePrefix state), ''

    if statetoApply?
      currentText = (getTitlePrefix statetoApply) + currentText

    return currentText

  getTitlePrefix = (state) -> "[#{state.title}] "

  allFilters =
    _filtersPanelSelector: '.wspace-folder-filterpanel-body'
    _filterGroupClass: "wspace-folder-filterpanel-filterpane wspace-tree-branch-root"
    _taistFiltersContainerId: 'wrike-taist-approval-filters'
    _filtersContainerClass: 'wspace-tree-branch'
    _filterSelectedClass: 'x-btn-pressed'
    _filtersFoldButtonClass: 'wspace-tree-foldButton'
    _filtersFoldClass: 'wspace-tree-folded'
    _searchFieldSelector: '.wrike-field-search input'

    _filters: null

    renderOnFiltersAppear: ->
      taistApi.wait.elementRender @_filtersPanelSelector, (filtersPanel) =>
        #TODO: remove possibly redundant check
        if not ($ '#' + @_taistFiltersContainerId)[0]?
          filtersContainer = @_renderFiltersContainer filtersPanel

          @_filters = []
          for _, state of states
            if state.title?
              filter = @_renderFilter state

              @_filters.push filter
              filtersContainer.append filter

    _renderFiltersContainer: (filtersPanel) ->
      filtersGroup = @_createFiltersGroupDom()

      previousFiltersGroup = filtersPanel.find(@_getSelectorFromClass @_filterGroupClass).last()
      previousFiltersGroup.after filtersGroup

      foldButton = filtersGroup.find @_getSelectorFromClass @_filtersFoldButtonClass
      foldButton.click =>
        filtersGroup.toggleClass @_filtersFoldClass

      return filtersGroup.find (@_getSelectorFromClass @_filtersContainerClass)

    _createFiltersGroupDom: -> $ """
<div class="#{@_filterGroupClass}" id="#{@_taistFiltersContainerId}">
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

    _renderFilter: (state, allFilters) ->
      filter = @_createFilterDom state.title

      filter.click =>
        targetState =
          if filter.hasClass @_filterSelectedClass
            null
          else
            state

        @_updateFilters targetState

        return false

    _createFilterDom: (filterTitle) -> $ """<a class="wrike-button-checkbox x-btn-noicon" href="#" style="width: auto;">#{filterTitle}</a>"""

    _updateFilters: (state) ->
      for filter in @_filters
        filter.toggleClass @_filterSelectedClass, state?.title is filter.text()

      applyStateToInput state, @_getSearchField()

    _getSearchField: -> $ @_searchFieldSelector

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
      taistApi.wait.change (=> @currentTask()), (task) ->
        if task?
          taistApi.wait.once (-> task.data.title?), ->
            callback task

    onCurrentTaskSave: (callback) ->
      taistApi.aspect.after $wrike.record.Base.prototype, 'getChanges', ->
        if @ is taistWrike.currentTask()
          callback @

  {start}
