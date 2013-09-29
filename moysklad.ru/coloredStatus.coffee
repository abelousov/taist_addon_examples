->
	utils = null

	start = (utilities, entryPoint) ->
		utils = utilities
		colorsStorage.init ->
			if entryPoint is 'user'
				rowsPainter.watchForRowsToRedraw()
			else
				settingsUI.waitToRedraw()

	colorsStorage =
		_stateColors: {}
		init: (callback) ->
			utils.wait.once (=> @_getCompanyName().length > 0), =>
				@_loadColorData @_getCompanyName(), callback

		_getCompanyName: -> $('.companyName>span').text()

		_colorsKey: 'stateColors'

		_loadColorData: (userKeyCommonForCompany, callback) ->
			utils.userData.get @_colorsKey, (
				(error, stateColors) =>
					@_stateColors = stateColors ? {}
					callback()
			), userKeyCommonForCompany

		getStateColor: (docType, state) -> @_stateColors[docType]?[state]

		_storeColorsOnServer: (cb) -> utils.userData.set @_colorsKey, @_stateColors, cb, @_getCompanyName()

		storeColor: (docType, state, color, callback) ->
			docTypeColors = @_stateColors[docType] ?= {}
			docTypeColors[state] = color
			@_storeColorsOnServer callback

	rowsPainter =
		watchForRowsToRedraw: ->
			utils.wait.elementRender (=> @_getDocsTable().find """tbody tr"""), (row) => @_redrawRow row

		_redrawRow: (row) ->
			stateColumnIndex = @_getStateColumnIndex @_getDocsTable()
			if stateColumnIndex?
				state = @_getRowStateByIndex row, stateColumnIndex
				color = colorsStorage.getStateColor @getCurrentDocType(), state
				if color?
					@_colorRow row, color

		_getRowStateByIndex: (row, index) -> $(row.find('td')[index]).find('[title]').text()
		_colorRow: (row, color) -> row.children().attr('style', 'background:' + color + '!important')

		getCurrentDocType: ->
			hashContents = location.hash.substring 1
			if (hashContents.indexOf('?') >= 0)
				hashContents = hashContents.substr(0, hashContents.indexOf('?'))

			return docTypesByHashes[hashContents]

		_getDocsTable: -> $ 'table.b-document-table'
		_getStateColumnIndex: (docsTable) ->
			columnNames = docsTable.find('thead').find('tr[class!="floating-header"]').find 'th'
			for column, i in columnNames
				if $(column).find('[title="Статус"]').length > 0
					return i

			return null

	settingsUI =
		waitToRedraw: ->
			@_waitDrawButton (saveButton) =>
				saveButton.click =>
					@_redrawColorPickers()

			@_onCurrentDocTypeChange => @_drawColorPickers()

		_waitDrawButton: (callback) ->
			utils.wait.elementRender @_saveButtonSelector, callback

		_onCurrentDocTypeChange: (callback) ->
			utils.wait.repeat (=> @_checkIfDocTypeChanged()), callback

		_checkIfDocTypeChanged: ->
			newDocType = @_getCurrentDocType()
			if newDocType? and newDocType != @_currentDocType
				@_currentDocType = newDocType
				true
			else
				false

		_getCurrentDocType: ->
			if location.hash is '#states' and (docTypeText = $('.gwt-TreeItem-selected').text()).length > 0 then docTypeText else null

		_currentDocType: null

		_saveButtonSelector: '.b-popup-button-green'

		_getStateInputs: -> $('input.gwt-TextBox[size="40"]')

		_redrawColorPickers: ->
			utils.wait.once (=> @_colorPickersRemoved()), (=> @_drawColorPickers())

		_colorPickersRemoved: -> $('.taistColorPicker').length is 0

		_getStateFromInput: (input) -> input.val()

		_drawColorPickers: ->
			for stateNameInput in @_getStateInputs()
				@_drawColorPicker ($ stateNameInput)

		_drawColorPicker: (jqStateInput) ->
			@_updateStateInputWithStoredColor jqStateInput
			@_addColorPicker jqStateInput

		_updateStateInputWithStoredColor: (input) ->
			storedColor = colorsStorage.getStateColor @_getCurrentDocType(), @_getStateFromInput input
			@_setInputColor input, storedColor ? 'white'

		_setInputColor: (input, color) -> input.css {background: color}
			
		_changeStateColor: (input, newColor) ->
			colorsStorage.storeColor @_getCurrentDocType(), (@_getStateFromInput input), newColor, =>
				@_updateStateInputWithStoredColor input
			
		_addColorPicker: (input) ->
			oldPickerCell = input.parent().next()
			oldPickerCell.hide()

			picker = $ '<td class="taistColorPicker"></td>'
			oldPickerCell.after picker

			colorPickCallback = (hexColor) =>
				console.log "color picked: #{hexColor}"
				@_changeStateColor input, '#' + hexColor

			picker.colourPicker {colorPickCallback}

	$.fn.getHexBackgroundColor = ->
		rgb = $(this).css('background-color')
		if not rgb
			return '#FFFFFF'

		hex_rgb = rgb.match /^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/
		if hex_rgb
			hex = (x) -> ("0" + parseInt(x).toString(16)).slice -2
			return "#" + hex(hex_rgb[1]) + hex(hex_rgb[2]) + hex(hex_rgb[3])
		else
			return rgb


	jQuery.fn.colourPicker = (conf) ->
		config = jQuery.extend {
		id: 'jquery-colour-picker',
		title: 'Pick a colour',
		speed: 500,
		openTxt: 'Open colour picker'
		inputId: 0
		colorPickCallback: ->
		}, conf

		colors = ['99', 'CC', 'FF']

		hexInvert = (hex)->
			r = hex.substr(0, 2)
			g = hex.substr(2, 2)
			b = hex.substr(4, 2)
			return 0.212671 * r + 0.715160 * g + 0.072169 * b < 0.5 ? 'ffffff': '000000'

		colourPicker = jQuery('#' + config.id)

		if (!colourPicker.length)
			colourPicker = jQuery('<div id="' + config.id + '"></div>').appendTo(document.body).hide()
			jQuery(document.body).click (event)->
				if (!(jQuery(event.target).is('#' + config.id) || jQuery(event.target).parents('#' + config.id).length))
					colourPicker.hide(config.speed)

		return this.each ()->
			select    = jQuery(this)

			iconDiv = jQuery('<img icondiv src="data:image/gif;base64,R0lGODlhFwATAPcAAM/R0WKXY9/j5bm8wWCUY+lmaquyt9LV1PPz81VwpVp1rX3lZXniZ67iZFh2qld1qlhyqeTmaX3jZMLGyuZpZ6/jZ+e2Z+iAZq2zueZlZV6UY8/P0c3Nz8vLz+qCaVmm3KngYVVzqea2aHbhX6extVZadWR8ZmB4YuuCbGGTYYvb3F98YmJ7ZVan26qut9fX17i7wMrLzbvAw7i8v7e8v6mssdnZ2crOz6itscfLznvhYonY3Om1aldbeGOXZlZad1ip3ufoaKistdTU1Nvb29DQ0OhracjMzcTFybm+wrW4vVSl3PHx8eizZ8rKzMnKzqats7e8wMDEx8HFxujobP/+/+q2a8bHybi7wtLR1tLS1KivtamttqqvtbG2uleo3cjJzc3Pzuq3Zqiws+traGKTZNXT1ofa3rDkZsvO1cfLzFZdd1V1plZac1yp4eayZld2rKivt1eq3F2p3eflaqzjYWOVZOO0ZrW6vsvLzednaGGXZsPDxbO2u+bnaFlaeauws6attaSvs7a+wLW9wMHCx6+3ulxceOPl5OaBaeLnaYnX2+Pj47/EyuiyaLO6wLa5wMnQ1mSVZsnKzGN9ZFx2qtrY2bq7wMTJzNfZ2Ku0uehoZ6uvunfhZaqvs+Pk5tHT0tPT01ek2rCzur7ExOlpaOlpamCSX+tpa6qusepqa47c3ova3pDc3LO4u+fpbOm0aMrMy63hZYvZ2b3Ax7/AxLG5vL7DxszKzeXnaujo6MbHy6zgYYvc3a/jZIza3rm8w8PDy66zucDDzHffYrS5v7a7v6yxtFNXdFem3ubmbHniYo3c4HrgYHrjY2GVZOi3a2CWZbzCwlRYdby/xldYdOTk5LS+v7/DxOmBaKqxuemDauuDaavhZf///YjY2crKyora267gY8TKytPS1+eEZ6ausefpaufqacXJyltddsfIyud/Zq20vIfY27DlY2F/Zefn52N8ZuWAZLC3va+0umJ8Y1xbeuXmZ+eCZunpba+2vP7//9bW1tjY2P///yH5BAAAAAAALAAAAAAXABMAAAj/AP/9Q2CNiD8bNvwpXLjQBhFGCAT+i+evn78XLxhqrHjxha5/TPqJHEmyZL8XJJlYOkDlnD4qZqBZsWDlALdt3FAMMYJKFZkhmUBleYUuSJBQFniIgaUFRbZyHrSUomDEVBZyRYrkouNH2QYeIpqIAHAhX6JEGwpQ2EQBwAYON/D5iaDoxps7TRzdYJdo3oUwGfQE5sChA64Yk2LkyPPkSI4Y4GI4eeIkRwc1OWKBOYLpSgU0vt7tWiBBwoJ1Pvb4CJDOBCV4JsZdCTalge06E3Q4k8Bggh1JBKJNWWFCHgskSPjckiWuQTdSyxg004HtWYoyBArZY7FihRQptWSA3OAFAgStEcRGdJJxSkN7GSfin5BGbQYNYFiiXJuB5dIAGDAMYgwMMwxAAww0EBLFDEpAwkorqzDjihtAADEHHgpUUgkcxdyjTg+HKPGIIV708osKs9jywRdfyOEFHGw84AA9bZSwRg997JPEKGeEs4MKGLTQQjIttPMABEcKU8IfP/xQTxICGLDIDu58w8kSonywxDEJhBACBNqUgEw102gjQBVpAMKFJ12Q4MKbLmwRxxgukLAFF12k4kIkVfDzzyfDaIKDEDXgEIggNQhhDg5Q1AAFBo0g4s0/AQEAOw==" />')

			icon    = jQuery('<a href="#"></a>')
			select.append(icon)
			icon.append(iconDiv)
			loc        = ''

			for rColor in colors
				for gColor in colors
					for bColor in colors
						hex        = rColor + gColor + bColor
						loc += '<li><a href="#"  rel="' + hex + '" style="background: #' + hex + '; colour: ' + hexInvert(hex) + ';"></a></li>'

			icon.click ()->
				iconPos    = icon.offset()
				heading    = config.title ? '<h2>' + config.title + '</h2>': ''
				colourPicker.html(heading + '<ul>' + loc + '</ul>').css
					position: 'absolute',
					left: iconPos.left + 'px',
					top: iconPos.top + 'px'

				colourPicker.show(config.speed)

				jQuery('a', colourPicker).click ()->
					hex = jQuery(this).attr('rel')
					config.colorPickCallback(hex, config.inputId)
					colourPicker.hide(config.speed)
					return false
				return false


	docTypesByHashes = 
		purchaseorder: "Заказ поставщику"
		invoicein: "Счет поставщика"
		supply: "Приёмка"
		purchasereturn: "Возврат поставщику"
		facturein: "Счёт-фактура полученный"
		customerorder: "Заказ покупателя"
		invoiceout: "Счет покупателю"
		demand: "Отгрузка"
		salesreturn: "Возврат покупателя"
		factureout: "Счёт-фактура выданный"
		pricelist: "Прайс-лист"
		loss: "Списание"
		enter: "Оприходование"
		move: "Перемещение"
		inventory: "Инвентаризация"
		processing: "Технологическая операция"
		processingorder: "Заказ на производство"
		internalorder: "Внутренний заказ"
		paymentin: "Входящий платеж"
		cashin: "Приходный ордер"
		paymentout: "Исходящий платеж"
		cashout: "Расходный ордер"

	return {start}
