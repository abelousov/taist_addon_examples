->
  taistApi = null

  start = (_taistApi, entryPoint) ->
    taistApi = _taistApi
    taistApi.haltOnError = true

    switch entryPoint
      when 'companyPage'
        drawExportButton()

  drawExportButton = ->
    previousButtonClass = 'follow_button'

    exportButton = jQuery '<input />',
      title: 'Export'
      value: 'Export'
      type: 'submit'
      "class": previousButtonClass + " exportButton"

      click: ->
        successMessage.hide()
        exportCompanyData ->
          successMessage.show 300

        return false

    (jQuery '.' + previousButtonClass).after exportButton

    successMessage = jQuery """<a href="#{resultsTableUrl}" target="_blank">succeeded</a>"""
    exportButton.after successMessage
    successMessage.hide()

  exportCompanyData = (callback) ->
    fieldValuesByNames = jQuery.extend getGeneralInfoFields(), getVariousFields()

    exportedData = {}
    for name, formField of formFieldsByNames
      exportedData[formField] = fieldValuesByNames[name]

    taistApi.proxy.jqueryAjax formHost, formPath, {type: 'POST', data: exportedData}, ->
      callback()

  getGeneralInfoFields = ->
    textValueFields = ['twitter', 'category', 'phone', 'founded', 'description']
    firstElementValueFields =
      'website': 'href'
      'blog': 'href'
      'email': 'title'

    fieldValues = {}

    addFieldValue = (fieldName, valueExtractor) ->
      captions = jQuery ".col1_content:first .td_left"
      for caption in captions when caption.textContent.toLowerCase() is fieldName
        targetCaptionCell = (jQuery caption)

        valueCell = targetCaptionCell.next()
        fieldValues[fieldName] = valueExtractor valueCell
        break

    for fieldName in textValueFields
      addFieldValue fieldName, (valueCell) -> valueCell.text()

    for fieldName, attrName of firstElementValueFields
      addFieldValue fieldName, (valueCell) -> valueCell.children('a').attr attrName

    return fieldValues

  getVariousFields = ->
    fieldValues = {}
    fieldValues[fieldName] = (jQuery selector).text() for fieldName, selector of {
      name: '#breadcrumbs span:last'
      funding_total: '.col1_funding_round_total .td_right2'
      employees: '#num_employees'
      tags: jQuery('a[href^="/tag/"]').parent()
    }

    return fieldValues

  formFieldsByNames =
    name: 'entry.1943171209'
    funding_total: 'entry.1045338686'
    tags: 'entry.463063990'
    website: 'entry.1221589467'
    blog: 'entry.735195729'
    twitter: 'entry.1396754322'
    category: 'entry.2054180868'
    phone: 'entry.570035841'
    email: 'entry.1028216727'
    employees: 'entry.1818327023'
    founded: 'entry.13262189'
    description: 'entry.1053914929'

  formHost = 'https://docs.google.com'
  formPath = '/forms/d/1Gh6uJXP7KyYqeEOe-zQAekBZfDFdt6g22a9aQ5zxL-M/formResponse'
  resultsTableUrl = 'https://docs.google.com/a/tai.st/spreadsheet/ccc?key=0At6Ryl-W8CwadHRhTU5TcjRUcEtFb0dpQWRxV0ZvTHc&usp=drive_web#gid=0'

  return {start}
