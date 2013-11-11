->
	utils = null
	container = null
	reminder = null

	start = (utilities) ->
		utils = utilities
		calendarUtils.init ->
			wrikeUtils.onTaskViewRender (task) -> draw task
			wrikeUtils.onTaskChange (updatedTask) -> updateReminderForTask updatedTask

	draw = (task) ->
		removeRemindersContainer()
		reminder = new Reminder task

		if not wrikeUtils.currentUserIsResponsibleForTask(task) or not reminder.canBeSet()
			return

		drawRemindersContainer()

		if not calendarUtils.authorized()
			drawAuthorization()

		else
			reminder.load =>
				drawReminderView()

	class Reminder
		@_calendarsList: null
		_reminderData: null
		_defaultSettings: null
		constructor: (@_task) ->
		load: (callback) ->
			Reminder._loadCalendars =>
				@_loadReminderData -> callback()

		exists: -> @_reminderData?

		@_loadCalendars: (callback) ->
			if not @_calendarsList?
				calendarUtils.loadCalendars (calendarsList) =>
					@_calendarsList = calendarsList
					callback()
			else
				callback()

		_loadReminderData: (callback) ->
			@_reminderData = null

			utils.userData.get "defaultSettings", (error, defaultSettingsData) =>
				@_defaultSettings = defaultSettingsData
				utils.userData.get @_task.data.id, (error, existingReminderData) =>
					eventId = existingReminderData?.eventId
					calendarId = existingReminderData?.calendarId

					if not eventId? or not calendarId?
						callback()
					else
						calendarUtils.getEvent eventId, calendarId, (event) =>
							eventIsActual = event? and event.status != "cancelled"
							if eventIsActual
								@_reminderData =
									event: event
									calendarId: calendarId
							callback()

		canBeSet: -> @_getRawBaseValue()?

		_getBaseDateTime: -> new Date @_getRawBaseValue()

		_getRawBaseValue: -> @_task.data["startDate"] ? @_task.data["finishDate"]

		getDisplayData: ->
			[hours, minutes] =
				if @exists()
					addLeadingZero = (number) -> if number < 10 then "0" + number else number

					reminderTime = new Date @_reminderData.event.start.dateTime
					[(addLeadingZero reminderTime.getHours()), (addLeadingZero reminderTime.getMinutes())]
				else
					['08', '00']

			hoursRange = ['06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23']
			minutesRange = ['00', '15', '30', '45']

			currentSettings =
				if @_reminderData?
					calendardId: @_reminderData.calendarId
					reminders: @_reminderData.event.reminders
				else @_defaultSettings

			usedNotifications = {}
			for notification in currentSettings?.reminders?.overrides ? []
				usedNotifications[notification.method] = yes

			return {hours, minutes, hoursRange, minutesRange, usedNotifications, calendars: Reminder._calendarsList, currentCalendar: currentSettings?.calendarId ? Reminder._calendarsList[0].id}

		delete: (callback) ->
			if @exists()
				calendarUtils.deleteEvent @_reminderData.event.id, @_reminderData.calendarId, =>
					@_reminderData = null
					callback()

		set: (hours, minutes, calendarId, useSms, useEmail, callback) ->
			eventStartDate = @_getBaseDateTime()
			eventStartDate.setHours hours, minutes
			notifications = []
			if useSms
				notifications.push "sms"
			if useEmail
				notifications.push "email"
			@_setByDateTime eventStartDate, calendarId, notifications, callback

		_setByDateTime: (eventStartDate, newCalendarId, notifications, callback) ->
			eventData = @_reminderData?.event ? {}

			eventData.summary = @_task.data["title"]
			eventData.start = {dateTime: eventStartDate}
			eventData.end = {dateTime: eventStartDate}
			eventData.description = "Task link: https://www.wrike.com/open.htm?id=#{@_task.data.id}"

			if notifications?
				eventData.reminders =
					useDefault: no
					overrides: []

				for method in notifications
					eventData.reminders.overrides.push {method, minutes: 0}

			newCallback = (newEvent) =>
				@_save newEvent, newCalendarId, callback

			if @_reminderData?
				calendarUtils.changeEvent @_reminderData.event.id, @_reminderData.calendarId, newCalendarId, eventData, newCallback
			else
				calendarUtils.createEvent newCalendarId, eventData, newCallback

		updateForTask: ->
			if @exists()
				startDateTime = @_task.data["startDate"]
				reminderDateTime = @_getBaseDateTime()
				startDateTime.setHours reminderDateTime.getHours(), reminderDateTime.getMinutes()

				@_setByDateTime startDateTime, @_reminderData.calendarId, null, ->

		_save: (newEvent, calendarId, callback) ->
			@_reminderData = {event: newEvent, calendarId}
			@_defaultSettings = {calendarId, reminders: newEvent.reminders}
			utils.userData.set @_task.data.id, {eventId: newEvent.id, calendarId}, =>
				utils.userData.set "defaultSettings", @_defaultSettings, -> callback()

	drawAuthorization = ->
		authButton = $ '<button>',
			text: 'Authorize Google Calendar'
			click: ->
				calendarUtils.authorize ->
					#TODO: использовать task из текущего view - он заведомо есть
					currentTask = wrikeUtils.getCurrentTask()
					if currentTask?
						draw currentTask
				return false

		container.append authButton

	drawRemindersContainer = ->
		taskDurationSpan =  $('.x-duration')
		container = $ '<span class="taist-reminders-container"></span>'
		taskDurationSpan.after container

	removeRemindersContainer = ->
		if container?
			container.remove()
			container = null

	drawReminderEditControl = ->
		container.html ''
		reminderEditControl = $ '<span></span>'

		displayData = reminder.getDisplayData()

		smsCheck = createNotificationCheck "Sms", "sms", displayData
		emailCheck = createNotificationCheck "E-mail", "email", displayData

		hoursSelect = createTimeSelect displayData.hoursRange, displayData.hours
		minutesSelect = createTimeSelect displayData.minutesRange, displayData.minutes
		setLink = $ '<a></a>',
			text: "Set"
			click: ->
				useSms = smsCheck.check.is(':checked')
				useEmail = emailCheck.check.is(':checked')
				reminder.set hoursSelect.val(), minutesSelect.val(), calendarSelect.val(), useSms, useEmail, ->
					drawReminderView()
		cancelLink = $ "<a></a>",
			text: 'Cancel'
			click: -> drawReminderView()

		calendarSelect = createCalendarSelect displayData.calendars, displayData.currentCalendar

		reminderEditControl.append icons.reminderExists, ': ', hoursSelect, '-', minutesSelect, ' ', smsCheck.check, smsCheck.label, ' ', emailCheck.check, emailCheck.label, ' ', calendarSelect, ' ',setLink, ' / ', cancelLink

		container.append reminderEditControl

	createNotificationCheck = (caption, id, displayData) ->
		check: $('<input>', {type: "checkbox", checked: displayData.usedNotifications[id], id: "taist-reminder-#{id}"})
		label: $ "<label for=\"Taist-reminder-#{id}\">#{caption}</label>"

	createTimeSelect = (timeValues, currentValue) ->
		closestValue = timeValues[0]
		for timeValue in timeValues
			if timeValue <= currentValue
				closestValue = timeValue
		timeSelect = $ '<select></select>'
		for timeValue in timeValues
			option = $ '<option></option>',
				text: timeValue
				val: timeValue
				selected: timeValue is closestValue
			timeSelect.append option

		return timeSelect

	createCalendarSelect = (calendarsList, currentCalendarId) ->
		calendarSelect = $ '<select></select>'
		for calendar in calendarsList
			calendarSelect.append $ '<option></option>',
				text: calendar.summary,
				val: calendar.id,
				selected: currentCalendarId == calendar.id

		return calendarSelect

	drawReminderView = ->
		container.html ''
		linkText = null
		iconHtml = null

		if reminder.exists()
			displayData = reminder.getDisplayData()

			iconHtml = icons.reminderExists
			linkText = """<span class="taist-reminders-linkText">#{displayData.hours}:#{displayData.minutes}"""
		else
			iconHtml = icons.noReminder
			linkText = ""

		editLink = $ "<a></a>",
			click: -> drawReminderEditControl()
			style: "border-bottom-style:none;"

		editLink.append iconHtml, linkText

		container.append editLink

		if reminder.exists()
			deleteLink = $ '<a></a>',
				text: 'X'
				click: ->
					reminder.delete ->
						drawReminderView()
				title: 'Delete'

			container.append ' (', deleteLink, ')'

	updateReminderForTask = (task)->
		reminderToUpdate = new Reminder task
		reminderToUpdate.load ->
			reminderToUpdate.updateForTask()

	calendarUtils =
		_client: null
		_auth: null
		_api: null
		_authorized: false
		init: (callback) ->
			jsonpCallbackName = 'calendarUtilsInitAfterApiLoad'
			window[jsonpCallbackName] = =>
				delete window[jsonpCallbackName]
				@_waitForGapiAndInit callback

			$('body').append "<script src=\"https://apis.google.com/js/client.js?onload=#{jsonpCallbackName}\"></script>"

		_waitForGapiAndInit: (callback) ->
			gapi = window["gapi"]
			@_client = gapi.client
			@_auth = gapi.auth
			@_client.setApiKey 'AIzaSyCLQdexpRph5rbV4L3V_9i0rXRRNiib304'

			window.setTimeout (=> @_getExistingAuth callback), 0

		_getExistingAuth: (callback) ->	@_getAuth true, callback

		authorize: (callback) -> @_getAuth false, callback

		_getAuth: (useExistingAuth, callback) ->
			authOptions =
				client_id: '181733347279'
				scope: 'https://www.googleapis.com/auth/calendar'
				immediate: useExistingAuth
			@_auth.authorize authOptions, (authResult) =>
				@_authorized = authResult and not authResult.error?
				if @_authorized
					@_loadCalendarApi callback
				else
					callback()

		_loadCalendarApi: (callback) ->
			@_client.load "calendar", "v3", =>
				@_api = @_client["calendar"]
				callback()

		authorized: -> @_authorized

		loadCalendars: (callback) ->
			request = @_api["calendarList"].list
				minAccessRole: "writer"
				showHidden: true

			request.execute (response) => callback response.items

		getEvent: (eventId, calendarId, callback) -> @_accessEvent "get", {calendarId, eventId}, callback

		deleteEvent: (eventId, calendarId, callback) ->	@_accessEvent "delete", {calendarId, eventId}, callback

		changeEvent: (eventId, currentCalendarId, newCalendarId, eventData, callback) ->
			utils.log "changing: ", arguments
			@_accessEvent "update", {resource: eventData, calendarId: currentCalendarId, eventId}, (newEvent) =>
				if currentCalendarId != newCalendarId
					@_moveEvent eventId, currentCalendarId, newCalendarId, callback
				else
					callback newEvent

		createEvent: (calendarId, eventData, callback) -> @_accessEvent "insert", {calendarId, resource: eventData}, callback

		_moveEvent: (eventId, currentCalendarId, newCalendarId, callback) ->
			utils.log "moving: ", arguments
			@_accessEvent "move", {calendarId: currentCalendarId, destination: newCalendarId, eventId}, callback

		_accessEvent: (method, params, callback) ->
			@_api.events[method](params).execute (eventOrResponse) ->
				if eventOrResponse.error?
					utils.error "couldn't #{method} event: ", params, eventOrResponse.error
				else
					callback eventOrResponse

	wrikeUtils =
		getCurrentUserId: -> w2.user.getUid()

		currentUserIsResponsibleForTask: (task) -> task.data["responsibleList"].indexOf(@getCurrentUserId()) >= 0

		getCurrentTaskView: -> window.Ext.ComponentMgr.get ($('.taskView').attr 'id')

		getCurrentTask: -> @getCurrentTaskView()?["record"]

		onTaskViewRender: (callback) ->
			cb = (taskView) -> callback taskView["record"], taskView
			taskViewClass = window.w2.folders.info.task.View
			utils.aspect.before taskViewClass, "showRecord", ->	cb @

			currentTaskView = @getCurrentTaskView()
			if currentTaskView?
				cb currentTaskView

		onTaskChange: (callback) -> utils.aspect.after Wrike.Task, "getChanges", (-> callback @)

	icons =
		noReminder: '<img class="taist-reminders-reminder-icon" title="Add reminder" alt="Add reminder" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAB0ElEQVRIDa1W23HCMBCMTf7jDqIOcDqgA1pwKsAMj2++GRigglBC6EAdBDogHUABQHYZiZHkkzFJNCMknXb3dHeycXK5XJ6atOFwuASuZ7Cr2WxWNuGlTUDE4CDKYt25tcXG5F4E4/E4P51OkyRJuq4IeJtWqzWZTqdb1x7Oax0MBoMCwh8hyV3D0ft8Pl+7NncedcCTn8/nL4B36G2XFM7TNH2LRRKtAdMCIYpr9NpmsCIm6oA5R/8Ey94cUYDGsD4uUHQwGo06BCG/mQuum1tOiBEdIPc5gN9wwLFRM5wKVnSAkHOI7zGqCiNiIEfaEh0AmIOwxfgqkSK2hxzUXsuIA5FTiSBWrIioZ5a4FQcolgLriJ557AYLw/WQ3pPc7/czvF/2KLA2BRbD9hT8xREPnVosFgdrvkVgxDU27Oaj4tR8wQE1tbhguznAxhJrhdNvcfrudfd3P22jdWUnZVkyLRqrNsQ3fxR3j7RDujqMgOEo7vyjOOUUepaiIHtMCnS+Of+rUaugtnSLOoiE/wUcGd29Yu+Q2gP+EzTrh7Ro9xbxjXm3s04hTrKFGK6fm+QEl2CCr4qei4VthXXp2qS5lyIJYG3ms6Uw63XTz5YfqiH1WdCp6QMAAAAASUVORK5CYII=" />'
		reminderExists: '<img class="taist-reminders-reminder-icon" title="Reminder set at" alt="Reminder set at" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAB5klEQVRIDa1W3W3CMBC+Qy1UKlXpBM0G0A3YoCuEl/48wQiMAE+t+gIjtBtkg8IGdIJSCalVEFw/OxBwck5SqZYi+z5/9519PlthEaEqjR+aIxLpWy7zWJ5Xgyp+tSoky9lKkHKPxymoD7hsB3zX7BDJkJhuHQmhNyIeystq5uAZozAAxENimWR8XFO4hyBTFzxY3gB25SzvoM7xtQ8uykj4xreTgjNAWow4c6RIZiDLzWCJ6Q+Q5Pw1rRzVfQdmz+eIqwbgx4uu5TC3jriFw9Qnw1ID0HaDyqEPEjJ9tZb45Lh6AGII8wLlGeQ8vIDxyTdPAKycaQb6dd7Fi/wpQHFZ6jFUn9wOfIela7qo5psLQBuTd/5CebZc9wqW9XV5zk3m3lWL6usFxCOcAQKV3GBXCxYWFp8GMvlc7qfSHSTicYTK2U+qOd076r1cUj2OrNaOkAbAxAgrCFD7s9zLqav50HailUwzhS2kxawc6TBPcMG19yl68DnF9W6Nzn5wmBxY0v+JQ44Do12Tp+8F8h5S8iyj+5eGJ15Co61UUdxFiA5WgN6WatlhQ4yX4EbwmyEt0XEVoSKl9DPnlOVpWJZj7BNELW+N9ZDvz/sOscFj2AMHUwwnRcp8CiW/LRRagGla9bflF7nn2hBRMZnFAAAAAElFTkSuQmCC">'

	return {start}
