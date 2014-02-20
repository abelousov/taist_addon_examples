->
  utils = null

  start = (utilities, entryPoint) ->
    utils = utilities
    storage.init ->
      currentPage =
        switch entryPoint
          when 'settings' then settingsForm
          when 'editIssue' then editIssueForm
          when 'createIssue' then createIssueForm
          when 'showIssues' then issuesList
      currentPage.render()

  settingsForm =
    _editor: null
    _compontentsTextArea: null
    render: ->
      githubUtils.addSettingsItem 'Components', @_getEditorRenderer()

    _getEditorRenderer: -> =>
      @_editor = $ @_editorTemplate

      @_componentsTextArea = @_editor.find 'textarea'
      saveButton = @_editor.find 'button'

      @_componentsTextArea.val @_getComponentsValueToDisplay()

      saveButton.click (e) =>
        e.preventDefault()
        @_saveComponentsData @_editor

      return @_editor

    _getComponentsValueToDisplay: ->
      componentStrings = (([comp.id,comp.name,comp.responsible].join ',') for comp in storage.getComponents())
      return componentStrings.join '\n'

    _saveComponentsData: (@editor) ->
      newComponentsData = @_componentsTextArea.val()

      storage.setComponentsData newComponentsData, (err) =>
        if err?
          @_displaySaveResult false, err.message + ' <a id="componentsJsonExample" href="#">Show example</a>'
          @_renderJsonExample()

        else
          @_displaySaveResult not err?, err?.message

    _displaySaveResult: (isSuccessful, message) ->
      [text, color] =
        if isSuccessful
          ['Saved successfully', 'green']
        else
          ['Error', 'red']

      (@_editor.find '#componentSaveResult').css('color', color).text text
      (@_editor.find '#componentSaveResultContents').html (if message? then ": #{message}" else '')

    _renderJsonExample: ->
      (@_editor.find '#componentsJsonExample').click =>
        @_componentsTextArea.val @_getComponentsExample() + @_componentsTextArea.val()
        return false

    _getComponentsExample: ->
      '=== Example:\n\n1,Authorization,fortknoxguard\n2,User manual,docsguru\n\n=== End of example\n\n'

    _editorTemplate: '
            <div class="tab-content">
                <div class="boxed-group">
                  <h3>Edit components</h3>
                  <div class="boxed-group-inner">
                      <textarea rows="20" class="componentsEditTextarea"></textarea>
                      <button type="submit" class="button primary componentsSaveButton">Save</button><span><span id="componentSaveResult"></span><span id="componentSaveResultContents"></span></span>
                      </div>
                </div>
            </div>
          '

  createIssueForm =
    render: ->
      utils.wait.elementRender '.assignee,infobar-widget', (previousWidget) =>
        componentsWidget = @_createComponentsWidget()
        previousWidget.after componentsWidget

        componentsDropdown = componentsWidget.find '.componentSelectDropdown'

        saveButton = $ '.form-actions .button.primary'

        saveButton.click ->
          selectedComponentId = componentsDropdown.val()
          console.log 'selected component: "', selectedComponentId + '"'
          if selectedComponentId is 'NOT_SET'
            #TODO: display error here
            return false

          else
            storage.storeComponentForNewTask selectedComponentId, ->
 
    _createComponentsWidget: ->
      componentOptionsArray = ("""<option value="#{component.id}">#{component.name}</option>""" for component in storage.getComponents())

      dropdownContents = $ """<span class="componentSelectionWidget infobar-widget text"></
        <label>Component: </label><select class="componentSelectDropdown"><option value="NOT_SET">---</option>#{componentOptionsArray}</select>
      </span>"""

      return dropdownContents

  storage =
    _getOwnerAndRepo: -> location.pathname.match(new RegExp('^/(\\w+/\\w+)'))[1]

    _components: null

    init: (callback) ->
      utils.companyData.setCompanyKey @_getOwnerAndRepo()

      utils.companyData.get 'components', (err, componentsData) =>
        if not err?
          @_components = componentsData
          callback()

    getComponents: ->
      @_components

    setComponentsData: (newComponentsValue, callback) ->

      errorMessage = @_setComponentsFromString newComponentsValue
      if errorMessage?
        callback new Error errorMessage

      else
        utils.companyData.set 'components', @_components, (err) ->
          if not err?
            callback null

    _setComponentsFromString: (componentsString) ->
      newComponents = []
      if componentsString.length is 0
       return 'empty components list'

      stringNumber = 0
      for componentString, stringNumber in componentsString.trim().split '\n'
        componentParts = componentString.trim().split ','
        if componentParts.length != 3
          return 'string ' + (stringNumber + 1) + ': data should be a list of strings "component_id,component_name,responsible_account"'

          newComponents.push {id: componentParts[0], name: componentParts[1], responsible: componentParts[2]}

      @_components = newComponents


    storeComponentForNewTask: (componentId, callback) ->
      utils.companyData.set 'componentForNewTask', componentId, (err) ->
        if not err?
          callback()

  issuesList =
    render: -> console.log 'rendered issues list'

  githubUtils =
    addSettingsItem: (itemName, contentsRenderer) ->
      utils.wait.elementRender '#repo-settings .menu', (menuContainer) ->
        newLink = $ "<a href=\"#\">#{itemName}</a>"
        menuContainer.append (($ '<li></li>').append newLink)

        newLink.click ->
          _formatLinkAsSelected newLink
          contentsContainer = $ '.repo-settings-content'
          contentsContainer.empty()

          contentsContainer.append contentsRenderer()
          return false

      _formatLinkAsSelected = (newLink) ->
        selectedFormatProperties = ['font-weight', 'border-left', 'color']
        previousSelectedLink = $ ('.js-selected-navigation-item.selected')

        for property in selectedFormatProperties
          selPropertyValue = previousSelectedLink.css property

          previousSelectedLink.css property, (newLink.css property)
          newLink.css property, selPropertyValue

  return {start}
