->
  taistApi = null

  start = (_taistApi) ->
    taistApi = _taistApi

    rowsPainter.watchForRowsToColor()

  rowsPainter =
    watchForRowsToColor: ->
      taistApi.wait.elementRender (=> ($ 'table.v-table-table').find """tbody tr"""), (row) => @_redrawRow row

    _redrawRow: (row) ->
      color = @_getRowColor row
      if color?
        @_colorRow row, color

    _getRowColor: (row) ->
      docType = @_getDocType row
      status = @_getStatus row

      color = colorsStorage.getStatusColor docType, status

      return color

    _getDocType: (row) -> @_getRowCellValue row, 'Receipt type'

    _getStatus: (row) ->
      regularStatus = @_getRowCellValue row, 'Status'

      if (@_isOverdue row) and regularStatus not in ["Paid", "Invalidated"]
        "Overdue"
      else
        regularStatus

    _isOverdue: (row) ->
      dueDateString = @_getRowCellValue row, 'Due date'

      dateParts = (Number.parseInt(datePart) for datePart in dueDateString.split '.')
      [day, month, year] = dateParts
      overdueStart = new Date year, (month - 1), (day + 1)

      return overdueStart < new Date()

    _getRowCellValue: (row, columnName) ->
      index = @_getColumnIndex row, columnName
      $(row.find('td')[index]).text()

    _colorRow: (row, color) -> row.attr('style', 'background:' + color + '!important')

    _getColumnIndex: (row, columnName) ->
      window.curRow = row
      headersTable = row.parents('.v-table-body').prev('.v-table-header-wrap')

      columnNames = headersTable.find 'td .v-table-caption-container'
      for column, i in columnNames
        if $(column).text() is columnName
          return i

      return null

  colorsStorage =
    getStatusColor: (docType, status) ->
      @_colorsStub[docType]?[status] ? @_colorsStub["<All>"]?[status]

    #TODO: add ability to use custom colors
    _colorsStub:
      "<All>":
        "Overdue": "#c0392b"
      "Sales invoice":
        "Not sent": "#f39c12"
        "Approved": "#2ecc71"

  return {start}
