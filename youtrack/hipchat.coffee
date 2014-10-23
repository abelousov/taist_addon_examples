->
  taistApi = null
  entryPoint = null
  services = null

  makePanelInactive = (panel) ->
    $ panel
      .removeClass('jt-panel-active')
      .addClass('jt-panel-inactive')

  getCompanyKey = () ->
    location.host

  linkServices = () ->
    taistApi.services.link
      source:
        name: 'youtrack'
        settings: services.settings.youtrack
      target:
        name: 'hipchat'
        settings: services.settings.hipchat
      converter: (record) ->
        updates = []
        for key, val of record.change then updates.push "#{key}: #{val.new}"
        console.log 'converter', updates
        '#' + record.id + ' ' + updates.join()
    , (a, b) -> console.log a, b

  createContainer = () ->
    hintsPanel = $('.jt-tabpanel-content>div:last')
    hipChatPanel = hintsPanel.clone().empty()
    hipChatPanel.appendTo hintsPanel.parent()

    makePanelInactive hipChatPanel

    hintsTab = $('.jt-tabpanel-navigation .jt-tabpanel-item:last')
    hipChatTab = hintsTab
      .clone()
      .attr('title', 'HipChat')
      .attr('tabid', 'HipChat')
      .removeClass('jt-panel-active')
      .appendTo(hintsTab.parent())
      .click ->
        for elem in $('.jt-panel-active')
          makePanelInactive(elem)
          $(this).addClass 'jt-panel-active'
          hipChatPanel.addClass 'jt-panel-active'

    $('.jt-tabpanel-item').click ->
      if this isnt hipChatTab[0]
        makePanelInactive hipChatPanel
        makePanelInactive hipChatTab

    hipChatTab
      .find('div div')
      .text('HipChat')

    return hipChatPanel

  createAddonInterface = () ->
    hipChatPanel = createContainer()

    $('<h2>')
      .text('HipChat Integration')
      .appendTo(hipChatPanel)

    fields = [
      {
        name: 'youtrack.serverName'
        note: 'Имя сервера (YouTrack)'
        type: 'text'
      }
    ]

    for elem in fields
      div = $ '<div>'
      switch elem.type
        when 'text'
          $('<span>')
            .addClass('taistLabel')
            .text(elem.note)
            .appendTo div

          $('<input>')
            .attr('type', 'text')
            .attr('name', elem.name)
            .appendTo div

      div.appendTo hipChatPanel

    $('<button>')
      .text('RUN')
      .appendTo(hipChatPanel)
      .click ->
        linkServices()

  onSettingsLoaded = () ->
    createAddonInterface()

  start = (_taistApi, _entryPoint) ->
    taistApi = _taistApi
    entryPoint = _entryPoint

    taistApi.companyData.setCompanyKey getCompanyKey()

    taistApi.companyData.get 'settings', (error, settings) ->
      defs =
        youtrack:
          serverName:'taist'
          login:'antonbelousov'
          password:'@00x*psM0$5^'
          projectId:'SH'
        hipchat:
          authToken: 'BGyWsdFa6mnfToP0isAUebV31534pPZ0OKzqI9vi'

      services =
        settings: $.extend {}, defs, settings

      onSettingsLoaded()

  {start}
