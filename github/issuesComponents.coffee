->
  utils = null

  start = (utilities, entryPoint) ->
    utils = utilities
    storage.init ->
      #settingsForm can be displayed dynamically, so wait for it to render from any page
      settingsForm.renderOnSettingsPageDisplay()

      if storage.componentsEnabled() and storage.getComponents().length > 0
        currentPage =
          switch entryPoint
            when 'editIssue' then editIssueForm
            when 'createIssue' then createIssueForm
            when 'showIssues' then issuesList

        currentPage?.render()

  settingsForm =
    _settingsControl: null
    _componentsTextArea: null
    _enabledCheckbox: null
    _requiredCheckbox: null
    _saveResults: null

    renderOnSettingsPageDisplay: ->
      githubUtils.addSettingsItem 'Components', =>
        headerControls: @_createHeaderCheckboxes()
        innerContents: @_createInnerContents()

    _createHeaderCheckboxes: ->
      @_enabledCheckbox = @_createHeaderCheckbox "componentsEnabled", storage.componentsEnabled()
      @_requiredCheckbox = @_createHeaderCheckbox "componentRequired", storage.componentRequired()

      return [
        (@_wrapChecboxInLabel @_enabledCheckbox, "Enabled"),
        (@_wrapChecboxInLabel @_requiredCheckbox, "Required in task")
      ]

    _createInnerContents: ->
      @_componentsTextArea = $ """<textarea rows="20" class="componentsEditTextarea"></textarea>"""
      @_componentsTextArea.val @_getComponentsValueToDisplay()

      saveButton = $ """<button type="submit" class="button primary componentsSaveButton">Save</button>"""
      saveButton.click =>
        @_saveComponentsData()
        return false

      @_saveResults = $ @_saveResultsTemplate

      return [@_componentsTextArea, saveButton, @_saveResults]

    _createHeaderCheckbox: (className, checked) ->
      return ($ """<input class="componentSettingsCheckbox #{className}" type="checkbox">""").prop('checked', checked)

    _wrapChecboxInLabel: (checkbox, labelText) ->
      return ($ """<label>#{labelText}</label>""").prepend checkbox

    _getComponentsValueToDisplay: ->
      componentStrings = (([comp.id,comp.name,comp.responsible].join ',') for comp in storage.getComponents())
      return componentStrings.join '\n'

    _saveComponentsData: ->
      settingsToSave =
        enabled: @_enabledCheckbox.prop 'checked'
        required: @_requiredCheckbox.prop 'checked'
        components: @_componentsTextArea.val()
      storage.saveSettings settingsToSave, (err) =>
        @_displaySaveResult err

    _saveResultsTemplate: """
        <span>
          <span id="componentSaveResult"></span>
          <span id="componentSaveResultContents"></span>
        </span>
      """

    _displaySaveResult: (err) ->
      success = not err?
      [text, color] =
        if success
          ['Saved successfully', 'green']
        else
          ['Error: ', 'red']

      (@_saveResults.find '#componentSaveResult').css('color', color).text text

      message =
        if success
          ''
        else
          err.message + ' <a id="componentsJsonExample" href="#">Show example</a>'
      (@_saveResults.find '#componentSaveResultContents').html message

      if not success
        @_displayJsonExample()

    _displayJsonExample: ->
      (@_saveResults.find '#componentsJsonExample').click =>
        @_componentsTextArea.val @_getComponentsExample() + @_componentsTextArea.val()
        return false

    _getComponentsExample: ->
      '=== Example:\n1,Authorization,fortknoxguard\n2,User manual,docsguru\n=== End of example\n\n'

  createIssueForm =
    _widget: null
    _componentsDropdown: null
    _required: -> storage.componentRequired()

    render: ->
      utils.wait.elementRender '.assignee.infobar-widget', (nextWidget) =>
        @_renderWidget nextWidget

        @_addCheckForRequiredComponent()

        @_changeAssigneeOnComponentChange()

        ($ @_saveButtonSelector).click => @_onSave()

    _renderWidget: (nextWidget) ->
      @_widget = $ @_getWidgetTemplate()
      nextWidget.prepend @_widget

      @_componentsDropdown = componentsDropdown.create 'plain', false
      @_componentsDropdown.renderTo @_widget.find '.dropdownContainer'

    _addCheckForRequiredComponent: ->
      if @_required()
        updateRequiredWarning = => @_widget[if @_componentsDropdown.getSelectedComponent()? then 'removeClass' else 'addClass'] 'componentRequiredWarning'

        @_componentsDropdown.onChange updateRequiredWarning
        updateRequiredWarning()

    _changeAssigneeOnComponentChange: ->
      assigneeWidget = $ '.js-composer-assignee-picker'
      @_componentsDropdown.onChange (componentId) ->
        openWidgetButton = assigneeWidget.find ".octicon-gear"
        openWidgetButton.click()

        findAssigneeDropdown = -> (assigneeWidget.find '.select-menu-modal-holder')

        utils.wait.once (-> findAssigneeDropdown().length > 0), ->
          component = storage.getComponent componentId
          responsible = component?.responsible ? ''
          responsibleRadioButton = assigneeWidget.find """input[type="radio"][value="#{responsible}"]"""
          if responsibleRadioButton.length > 0
            responsibleRadioButton.click()
          else
            (assigneeWidget.find '.js-menu-close').click()

            if component?
              setTimeout ( ->
                alert "Error: user '#{responsible}' specified as responsible for component '#{component.name}' not found in repository. Please check components settings"
              ), 500

    _onSave: ->
      if not @_componentsDropdown.getSelectedComponent()?
        if @_required()
          fadeDuration = 400
          @_widget.fadeOut(fadeDuration).fadeIn(fadeDuration)
          return false

        else
          return

      else
        storage.storeComponentForNewTask @_componentsDropdown.getSelectedComponent(), ->

    _saveButtonSelector: '.form-actions .button.primary'

    _getWidgetTemplate: -> """
        <span class="componentSelectionWidget infobar-widget text #{if @_required() then 'componentRequiredWarning'}"></
          <label>Component: </label><span class="dropdownContainer"></span>
        </span>
      """

  componentsDropdown =
    _emptyComponentValue: 'NOT_SET'
    create: (type, preserveEmptyOption) ->
      concreteDropdown = @_dropdownImplementations[type]
      concreteDropdown.create @_getComponentOptions()

      return @_getDropdownWrapper concreteDropdown, preserveEmptyOption

    _getComponentOptions: ->
      componentOptions = ({value: comp.id, name: comp.name} for comp in storage.getComponents())
      componentOptions.unshift {value: @_emptyComponentValue, name: '---------------'}

      return componentOptions

    _getDropdownWrapper: (dropdown, preserveEmptyOption) ->
      renderTo: (container) -> dropdown.renderTo container
      getSelectedComponent: ->
        if (selectedValue = dropdown.getValue()) is componentsDropdown._emptyComponentValue
          null
        else
          selectedValue

      setSelectedComponent: (componentId) ->
        dropdown.setValue componentId ? componentsDropdown._emptyComponentValue

        #if component is required and set, empty option will be removed unless opposite is set
        if storage.componentRequired() and not preserveEmptyOption and componentId?
          dropdown.removeOption componentsDropdown._emptyComponentValue

      onChange: (handler) -> dropdown.onChange =>
        handler @getSelectedComponent()

    _dropdownImplementations:
      plain:
        _plainDropdown: null
        create: (options) ->
          componentOptionsArray = ("""<option value="#{option.value}">#{option.name}</option>""" for option in options)
          @_plainDropdown = $ """<select class="componentSelectDropdown">#{componentOptionsArray}</select>"""
        renderTo: (container) -> container.append @_plainDropdown
        getValue: -> @_plainDropdown.val()
        setValue: (value) -> @_plainDropdown.val value
        removeOption: (optionValue) -> (@_plainDropdown.find """[value="#{optionValue}"]""").remove()
        onChange: (handler) -> @_plainDropdown.change handler

      github:
        _githubDropdown: null
        create: (options) -> @_githubDropdown = githubUtils.createDropdown '', "Components", options
        renderTo: (container) -> @_githubDropdown.renderTo container
        getValue: -> @_githubDropdown.getValue()
        setValue: (value) -> @_githubDropdown.setValue value
        removeOption: (optionValue) -> @_githubDropdown.removeOption optionValue
        onChange: (handler) -> @_githubDropdown.onChange handler

  editIssueForm =
    _widget: null
    _componentsDropdown: null
    render: ->
      @_assignComponentToFreshlyCreatedTask =>
        @_renderWidget()
        @_setCurrentComponent =>
          @_listenToComponentChangeAndSave()

    _assignComponentToFreshlyCreatedTask: (callback) ->
      storage.assignComponentIfTaskJustCreated @_getCurrentTaskId(), -> callback()

    _renderWidget: ->
      @_widget = $ @_widgetTemplate
      $(@_previousWidgetSelector).after @_widget
      @_componentsDropdown = componentsDropdown.create 'github', true
      @_componentsDropdown.renderTo @_widget.find '.dropdownContainer'

    _setCurrentComponent: (callback) ->
      storage.getComponentForTask @_getCurrentTaskId(), (componentId) =>
        @_componentsDropdown.setSelectedComponent componentId
        callback()

    _listenToComponentChangeAndSave: ->
      @_componentsDropdown.onChange (newComponentId) =>
        storage.assignComponentToTask @_getCurrentTaskId(), newComponentId, ->

    _previousWidgetSelector: '.discussion-sidebar-item.sidebar-labels'

    _widgetTemplate:
      """
<div class="discussion-sidebar-item sidebar-milestone">
<div class="select-menu js-menu-container js-select-menu is-showing-clear-item">
  <h3 class="discussion-sidebar-heading">
    Component
  </h3>
</div>

<span class="js-milestone-infobar-item-wrapper">
    <span class="dropdownContainer"></span>
</span>
</div>
    """
    _getCurrentTaskId: -> location.pathname.match(/\d+(?=$)/)[0]

  storage =
    componentsEnabled: -> @_settings.enabled
    componentRequired: -> @_settings.required
    _getOwnerAndRepo: -> location.pathname.match(new RegExp('^/(\\w+/\\w+)'))[1]

    _settings: null

    init: (callback) ->
      utils.companyData.setCompanyKey @_getOwnerAndRepo()

      utils.companyData.get 'settings', (settings) =>
        @_settings = settings ? {}
        callback()

    getComponents: -> @_settings.components ? []

    getComponent: (componentId) ->
      return comp for comp in @_settings.components when comp.id is componentId

    saveSettings: (settingsToSave, callback) ->
      @_settings.enabled = settingsToSave.enabled
      @_settings.required = settingsToSave.required

      if @_settings.enabled
        errorMessage = @_setComponentsFromString settingsToSave.components
        if errorMessage?
          callback new Error errorMessage
          return

      utils.companyData.set 'settings', @_settings, ->
        callback()

    _setComponentsFromString: (componentsString) ->
      newComponents = []
      if componentsString.length is 0
        return 'empty components list'

      for compString, stringNumber in componentsString.trim().split '\n'
        componentParts = compString.trim().split ','
        if componentParts.length != 3
          return """string #{stringNumber + 1}: data should be a list of strings "component_id,component_name,responsible_account\""""
        else
          newComponents.push {id: componentParts[0], name: componentParts[1], responsible: componentParts[2]}
      @_settings.components = newComponents

      return null

    storeComponentForNewTask: (componentId, callback) ->
      utils.userData.set 'componentForNewTask', componentId, -> callback()

    _deleteComponentForNewTask: (callback) ->
      utils.userData.delete 'componentForNewTask', -> callback()

    _getComponentForNewTask: (callback) ->
      utils.userData.get 'componentForNewTask', (componentId) -> callback componentId

    assignComponentIfTaskJustCreated: (taskId, callback) ->
      @_getComponentForNewTask (componentId) =>
        if componentId?
          @assignComponentToTask taskId, componentId, =>
            @_deleteComponentForNewTask ->
              callback()
        else
          callback()

    assignComponentToTask: (taskId, componentId, callback) ->
      utils.companyData.setPart 'assignedComponents', taskId, componentId, -> callback()

    getComponentForTask: (taskId, callback) ->
      utils.companyData.getPart 'assignedComponents', taskId, (componentId) -> callback componentId

    getAssignedComponents: (callback) ->
      utils.companyData.get 'assignedComponents', (assignedComponents) -> callback assignedComponents

  issuesList =
    _assignedComponents: null
    _widget: null
    _currentComponent: null
    render: ->
      storage.getAssignedComponents (assignedComponents) =>
        @_assignedComponents = assignedComponents

        utils.wait.elementRender '.issues-list', =>
          @_renderComponentFilter()
          @_filterIssuesByComponent()

    _renderComponentFilter: ->
      sortingSelect = $ '.js-issues-sort'
      @_widget = $ @_widgetTemplate

      #always show option for empty component to reset filter
      @_componentsDropdown = componentsDropdown.create 'github', true
      @_componentsDropdown.renderTo @_widget.find '.dropdownContainer'

      sortingSelect.before @_widget

      @_componentsDropdown.setSelectedComponent @_currentComponent

      @_componentsDropdown.onChange (selectedComponent) =>
        @_currentComponent = selectedComponent
        @_filterIssuesByComponent()

    _widgetTemplate: """<span class="componentFilterWidget"><span class="dropdownContainer"></span>
      </span>"""

    _filterIssuesByComponent: ->
      for issueDOM in ($ '.issue-list-item')
        issueId = issueDOM.id.substring 'issue_'.length

        jqIssue = $ issueDOM
        if @_currentComponent? and @_assignedComponents[issueId] != @_currentComponent
          jqIssue.hide()
        else
          jqIssue.show()

  githubUtils =
    _settingsItemLinkClass: 'js-selected-navigation-item'
    _settingsTabContainerSelector: '.repo-settings-content'
    _settingsMenuSelector: '#repo-settings .menu'

    addSettingsItem: (itemName, createTabContents) ->
      utils.wait.elementRender @_settingsMenuSelector, (menu) =>
        newSettingsTab = @_createSettingsItemTab itemName
        menuItemClick = =>
          ($ @_settingsTabContainerSelector).empty().append newSettingsTab

        menuItem = @_createSettingsMenuItem itemName, menuItemClick
        menu.append menuItem

        tabContents = createTabContents()

        for headerControl in tabContents.headerControls
          (newSettingsTab.find '.boxed-group.boxed-group-action').append headerControl

        for contents in tabContents.innerContents
          (newSettingsTab.find '.boxed-group-inner').append contents

    _createSettingsMenuItem: (itemName, onSelected) ->
      do ->
        newItem = $ "<a></a>",
            href: "#",
            text: itemName
            click: ->
              githubUtils._switchSelectedMenuItemTo newItem
              onSelected()
              return false
        newItem.addClass @_settingsItemLinkClass

        return ($ '<li></li>').append newItem

    _switchSelectedMenuItemTo: (newSelectedItem) ->
      selectedClass = 'selected'
      previousSelectedLink = $ ".#{@_settingsItemLinkClass}.#{selectedClass}"

      newSelectedItem.addClass selectedClass
      previousSelectedLink.removeClass selectedClass

    _createSettingsItemTab: (itemName) -> $ """
      <div class="tab-content">
          <div class="boxed-group">
            <span class="boxed-group boxed-group-action">
            </span>
            <h3>#{itemName}</h3>
            <div class="boxed-group-inner">
            </div>
          </div>
      </div>
"""

    createDropdown: (caption, listCaption, options)->
      dropdownContents = $ @_createDropdownFromTemplate caption, listCaption
      currentValue = null
      changeHandler = null

      itemsByValues = {}

      itemsList = dropdownContents.find '.select-menu-list'

      addOption = (option) =>
        dropdownItem = @_createDropdownItemFromTemplate option.name
        dropdownItem.click ->
          currentValue = option.value

          if changeHandler?
            changeHandler()

        itemsByValues[option.value] = dropdownItem
        itemsList.append dropdownItem

      for opt in options
        addOption opt

      return {
        renderTo: (container) -> container.append dropdownContents
        getValue: -> currentValue
        setValue: window.setValue = (newValue) ->

          #emulate human pressing on buttons to trigger github UI logic automatically;
          dropdownOpenButton = dropdownContents.find ".#{githubUtils._dropdownOpenButtonClass}"
          dropdownOpenButton.click()

          #hide menu to avoid blinking when it will be showed automatically
          menuContents = dropdownContents.find ".#{githubUtils._dropdownMenuContentsClass}"
          menuContents.hide()

          setTimeout ( ->
            itemsByValues[newValue].click()
            menuContents.show()
          ), 0

        onChange: (handler) ->
          changeHandler = => handler @getValue()

        addOption
        removeOption: (value) -> itemsByValues[value].remove()
      }

    _dropdownOpenButtonClass: 'minibutton'
    _dropdownMenuContentsClass: 'select-menu-modal'

    _createDropdownFromTemplate: (caption, listCaption) -> """
<div class="select-menu js-menu-container js-select-menu">
  <span class="#{@_dropdownOpenButtonClass} select-menu-button js-menu-target" role="button" tabindex="0" aria-haspopup="true">
    <i>#{caption}</i>
    <span class="js-select-button"></span>
  </span>

  <div class="select-menu-modal-holder js-menu-content js-navigation-container" aria-hidden="true">

    <div class="select-menu-modal">
      <div class="select-menu-header">
        <span class="select-menu-title">#{listCaption}</span>
        <span class="octicon octicon-remove-close js-menu-close"></span>
      </div> <!-- /.select-menu-header -->

      <div class="select-menu-list">
      </div>

    </div> <!-- /.select-menu-modal -->
  </div> <!-- /.select-menu-modal-holder -->
</div>
"""
    _createDropdownItemFromTemplate: (name) -> $ """
        <a class="select-menu-item js-navigation-open js-navigation-item">
          <span class="select-menu-item-icon octicon octicon-check"></span>
          <span class="select-menu-item-text js-select-button-text">#{name}</span>
        </a>
"""

  return {start}
