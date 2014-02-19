->
  utils = null

  start = (utilities, entryPoint) ->
    utils = utilities
    storage.init()

    switch entryPoint
      when 'settings' then settingsPage.render()

  settingsPage =
    render: ->
      utils.wait.elementRender '.menu', (menuContainer) =>
        @_appendComponentsLink menuContainer

    _appendComponentsLink: (menuContainer) ->
      componentsLink = $ '<a href=\'components\'>Components</a>'

      menuContainer.append (($ '<li></li>').append componentsLink)
      componentsLink.click (e) =>
        @_formatLinkAsSelected componentsLink
        @_renderComponentsEditor()

        return false


    _formatLinkAsSelected: (componentsLink) ->
      selectedFormatProperties = ['font-weight', 'border-left', 'color']
      currentSelectedLink = $ ('.js-selected-navigation-item.selected')

      for property in selectedFormatProperties
        selPropertyValue = currentSelectedLink.css property

        currentSelectedLink.css property, (componentsLink.css property)
        componentsLink.css property, selPropertyValue

    _renderComponentsEditor: ->
      container = $ '.repo-settings-content'

      container.html @_editorTemplate

      contentsTextArea = container.find 'textarea'
      saveButton = container.find 'button'

      storage.get (componentsData) ->
        contentsTextArea.val componentsData

      saveButton.click (e) =>
        e.preventDefault()
        @_saveComponentsData container, contentsTextArea

    _saveComponentsData: (container, contentsTextArea) ->
      newComponentsData = contentsTextArea.val()

      correctData = true
      try
        componentsJSON = JSON.parse newComponentsData
        console.log 'parsed: ', componentsJSON
      catch
        correctData = false

      if not correctData
        @_displaySaveResult container, false, 'components data should be a valid JSON containing component ids and names and accounts of people responsible for them. Show <a id="componentsJsonExample" href="#">example</a>'

        @_renderJsonExample container, contentsTextArea

      else
        storage.set componentsJSON, (err) =>
          @_displaySaveResult container, not err?, err?.message

    _displaySaveResult: (container, isSuccessful, message) ->
      [text, color] =
        if isSuccessful
          ['Saved successfully', 'green']
        else
          ['Error', 'red']

      (container.find '#resultType').css('color', color).text text
      if message?
        (container.find '#resultContents').html ': ' + message

    _renderJsonExample: (container, contentsTextArea) ->
      (container.find '#componentsJsonExample').click (e) ->
        e.preventDefault()

        example = '{\n  "1": {\n    "name": "Authorization",\n    "responsible": "fortnox"\n  },\n\n  "2": {\n    "name": "User manual",\n    "resonsible": "docsguru"\n  }\n}'

        contentsTextArea.val ("=== Example:\n #{example} \n=== End of example\n\n") + contentsTextArea.val()

    _editorTemplate: '
            <div class="tab-content">
                <div class="boxed-group">
                  <h3>Edit components</h3>
                  <div class="boxed-group-inner">
                      <textarea rows="20" style="width: 100%; margin: 10px 0;"></textarea>
                      <button type="submit" class="button primary" style="margin-right: 10px;margin-bottom: 10px;">Save</button><span id="resultType"></span><span id="resultContents"></span>
                      </div>
                </div>
            </div>
          '

  storage =
    _componentContentsKey: "components"
    _getOwnerAndRepo: -> location.pathname.match(new RegExp('^/(\\w+/\\w+)'))[1]

    init: -> utils.companyData.setCompanyKey @_getOwnerAndRepo()

    get: (callback) ->
      utils.companyData.get @_componentContentsKey, (err, res) ->
        if not err?
          callback res
    set: (newValue, callback) ->
      utils.companyData.set @_componentContentsKey, newValue, (err) -> callback err



  return {start}
