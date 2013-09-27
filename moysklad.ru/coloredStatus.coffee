->
	utils = null
	userSettings = []

	start = (utilities, entryPoint) ->
		utils = utilities
		utils.wait.once (->getCompanyName().length > 0), ->
			getUserSettings ->
				if entryPoint is 'user'
					colorRows()
				else
					drawColorSettings()

	getCompanyName = -> $('.companyName>span').text()

	getUserSettings = (callback) ->
		utils.userData.get '', (
			(error, value) ->
				userSettings = value
				callback()
		), getCompanyName()

	getColorOfStatus = (docType, statusName)->
		contKey = JSON.stringify
			currentDocType: docType
			status: statusName
		for setting in userSettings
			if setting.key == contKey
				return setting
		return null

	getColorOfStatusByHash = (hash, statusName)->
		if hash?
			cutHash = hash
			if (hash.indexOf('?') >= 0)
				cutHash = hash.substr(0, hash.indexOf('?'))
			for docHash in docMap
				if docHash.hash == cutHash
					return (getColorOfStatus docHash.key, statusName)?.value

	setUserSettings = (setting, cb)-> utils.userData.set setting.key, setting.value, cb, getCompanyName()

	colorRows = ->
		currentRenderedAttrValue = Math.random()

		utils.wait.repeat (-> (getDocsTable().find "tbody tr[renderedColor!=\"#{currentRenderedAttrValue}\"]").length > 0), ->
			rows = getRowsToRedraw currentRenderedAttrValue
			redrawRows rows, location.hash
			rows.attr('renderedColor', currentRenderedAttrValue)

		utils.wait.hashChange -> currentRenderedAttrValue = Math.random()

	getRowsToRedraw = (newRenderedAttrValue) -> getDocsTable().find """tbody tr[renderedColor!="#{newRenderedAttrValue}"]"""

	redrawRows = (rows, currentHash) ->
		docsTable = getDocsTable()
		statusColumnIndex = getStatusColumnIndex docsTable
		if statusColumnIndex?
			getColorByStatus = (statusName) -> getColorOfStatusByHash currentHash, statusName

			for row in rows
				drawRow ($ row), getColorByStatus, statusColumnIndex

		docsTable.find('td:not([style*="background"])').attr('style', 'background:#FFFFFF !important')

	drawRow = (jqRow, getColorByStatus, statusColumnIndex) ->
		color = getColorByStatus $(jqRow.find('td')[statusColumnIndex]).find('[title]').text()
		if color?
			jqRow.children().attr('style', 'background:' + color + '!important')

	getDocsTable = -> $ 'table.b-document-table'
	getStatusColumnIndex = (docsTable) ->
		index = null
		for column, i in docsTable.find('thead').find('tr[class!="floating-header"]').find 'th'
			if $(column).find('[title="Статус"]').length
				index = i
				break

		return index

	drawColorSettings = ->
		waitDrawButton()
		wait = ->
			utils.wait.once statesSettingsDisplayed, ->
			setTimeout (->
				drawColorPickers()
				wait()), 0

		wait()

	statesSettingsDisplayed = -> onStatesSettingsPage() and someStatesExist()
	onStatesSettingsPage = -> location.href.indexOf('app/admin/#states') > 0
	someStatesExist = -> $('input.gwt-TextBox[size="40"]').length > 0

	waitDrawButton = ->
		utils.wait.elementRender saveButtonSelector, (saveButton) ->
			saveButton.click saveCurrentStatesColors

	saveButtonSelector = '.b-popup-button-green'

	saveCurrentStatesColors = ->
		currentDocType = ($ '.gwt-TreeItem-selected').text()
		for inputObj in $ '[colorPId]'
			input = $ inputObj
			value = input.val()
			if value.length
				key = JSON.stringify
					currentDocType: currentDocType
					status: input.val()

				value = input.getHexBackgroundColor()
				currentColor = getColorOfStatus currentDocType, input.val()
				if currentColor?
					currentColor.value = value
				else
					userSettings.push
						key: key
						value: value

				setUserSettings {key, value}, ->

	drawColorPickers = ->
		currentDocType = $('.gwt-TreeItem-selected').text()
		for status, i in $('input.gwt-TextBox[size="40"]')
			curDiv = $(status)
			inputId = curDiv.attr('colorPId')
			if $('#color_picker_' + inputId).length == 0
				curDiv.css
					background: 'white'
				if !curDiv.attr('colorPId')
					curDiv.attr('colorPId', i)
				color = getColorOfStatus(currentDocType, curDiv.val())
				if color?
					curDiv.css
						background: color.value
					curDiv.attr('check', 'true')
				picker = $('<td><div id="color_picker_' + i + '"></div></td>')
				curDiv.parent().after(picker)
				colorPickCall= (hex, inputId)->
					$('[colorPId=' + inputId + ']').css({background: '#' + hex})

				picker.colourPicker
					title: ''
					inputId: i
					colorPickCallback: colorPickCall
			if !curDiv.attr('check')
				color = getColorOfStatus(currentDocType, curDiv.val())
				if color?
					curDiv.css
						background: color.value
					curDiv.attr('check', 'true')

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
		colorPickCallback: (hex, inputId)->
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


	docMap =[
		{key: "Заказ поставщику", hash: "#purchaseorder"},
		{key: "Счет поставщика", hash: "#invoicein"},
		{key: "Приёмка", hash: "#supply"},
		{key: "Возврат поставщику", hash: "#purchasereturn"},
		{key: "Счёт-фактура полученный", hash: "#facturein"},
		{key: "Заказ покупателя", hash: "#customerorder"},
		{key: "Счет покупателю", hash: "#invoiceout"},
		{key: "Отгрузка", hash: "#demand"},
		{key: "Возврат покупателя", hash: "#salesreturn"},
		{key: "Счёт-фактура выданный", hash: "#factureout"},
		{key: "Прайс-лист", hash: "#pricelist"},
		{key: "Списание", hash: "#loss"},
		{key: "Оприходование", hash: "#enter"},
		{key: "Перемещение", hash: "#move"},
		{key: "Инвентаризация", hash: "#inventory"},
		{key: "Технологическая операция", hash: "#processing"},
		{key: "Заказ на производство", hash: "#processingorder"},
		{key: "Внутренний заказ", hash: "#internalorder"},
		{key: "Входящий платеж", hash: "#paymentin"},
		{key: "Приходный ордер", hash: "#cashin"},
		{key: "Исходящий платеж", hash: "#paymentout"},
		{key: "Расходный ордер", hash: "#cashout"}
	]

	return {start}
