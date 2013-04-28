->
	utils = null
	start = (utilities)->
		utils = utilities
		wrikeUtils.onTaskChange -> taskWithTimerView.render()
		timer.load ->
			wrikeUtils.onTaskViewRender drawSelectedTask
			taskWithTimerView.render()

	drawSelectedTask = (task, taskView) ->
		taskView.taistTimerButton ?= createTimerButton()
		taskView.taistTimerButton.render task

	taskWithTimerView =
		_getParent: -> $ '.w2-actions-toolbar .x-toolbar-left-row'
		_contentsId: 'taist-timetracker-currentTask'
		_getContentsContainer: ->
			contentsContainer = @_getParent().find "#" + @_contentsId
			if contentsContainer.length == 0
				contentsContainer = $ """<td id="#{@_contentsId}"></td>"""
				@_getParent().append contentsContainer

			return contentsContainer

		isVisible: -> @_getParent().length > 0

		render: ->
			if @isVisible()
				setHtml = (htmlString) => @_getContentsContainer(). html htmlString
				if timer.isStarted()
					timer.getTaskWithTimerTitle (taskTitle) =>
						setHtml """<span id="taist-timetracker-currentCaption">Current: </span><a href="https://www.wrike.com/open.htm?id=#{timer['taskId']}" class="start">#{taskTitle}</a>"""
				else
					setHtml ''

	createTimerButton = ->
		render: (task) ->
			@_task = task
			@_redraw()

		_redraw: ->
			icon = @icons[@_getState()] ? ''
			@_getContainer().html icon

		_getState: ->
			if wrikeUtils.currentUserIsResponsibleForTask @_task
				if not timer.isStarted()
					"start"
				else if timer.taskId == @_task.data["id"]
					"stop"

		_getContainer: ->
			predecessor = $('td.info-tracking')
			containerClass = "taist-timetrack"
			container = predecessor.siblings "." + containerClass
			if container.length == 0
				container = $ "<td></td>",
					class: containerClass
					click: => @_onClick()

				predecessor.after container

			return container

		_onClick: ->
			state = @_getState()

			if state is "start"
				timer.start @_task, =>
					@_redraw()
					taskWithTimerView.render()

			else if state is "stop"
				@_openTimeRecordWindow()

		_openTimeRecordWindow: ->
			spentMilliseconds = (new Date().getTime() - timer.startTime)
			spentHours = spentMilliseconds/(1000*60*60)
			roundedHoursString = spentHours.toFixed(1)
			$('#taskview-tracking-link').click()
			$('.w3-input-element').children().first().next().val roundedHoursString
			$('.x-btn-plain-c').children().children()

			saveTimeButton = $('.actions').find("button")
			if not saveTimeButton.timetrackHandlerAdded?
				saveTimeButton.timetrackHandlerAdded = true
				saveTimeButton.bind 'click', =>
					timer.stop ->

		icons:
			start: '<img class="timer-icon" alt="Start timer" title="Start timer" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAA40lEQVQ4EZ2T0RGCMAyG/1TfdQNX0Q0cwRHoBDIBMAIrOIE4ghvoBvquhNRe7npcwRa4Etrm/y5pE5gC7t0yM5YMEgCD8JZv0wMN1/xCxmN+voyN2LMhPFaWigw9fARjBeFJjPJTczveGs/jAPVKAM0DAlDPOMn5dLqk1p+BzqYsYyeOV2OpI0v70C0tglAh/wzcZJQuokUA5QnkkpaCKiJ2EcClIEV36Gs+riPQyaUwd3VKAxDuco1F7BrnAVpI1XRFxgEJwngKvivLb8WNOvyzPgJtZ2np3HZ2ACsH1OYKNbIBKYWPOrHmye0AAAAASUVORK5CYII="/>'
			stop: '<img class="timer-icon" alt="Stop timer" title="Stop timer" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQCAYAAAAvf+5AAAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAAPklEQVQoFWNkKmT4wPCfgZ8BBBgZPv7t+y8AYjIXMaKIM8EVgWRhGrCwmUBixIBRhXhDaZgFDzBpwb2Lhw0Am8sRg1PD+GUAAAAASUVORK5CYII="/>'

		_task: null
		_timer: null

	timer =
		taskId: null
		startTime: null
		load: (callback) ->
			utils.userData.get "timer", (error, timerData) =>
				if timerData?
					wrikeUtils.getTask timerData.taskId, (task) =>

						if task? and not task["isDeleted"]
							@taskId = timerData.taskId
							@startTime = timerData.startTime
						callback()
				else
					callback()

		isStarted: -> @taskId?

		stop: (callback) -> @_save null, callback

		start: (task, callback) -> @_save {taskId: task.data.id, startTime: new Date().getTime()}, callback

		_save: (timerData, callback) ->
			@taskId = timerData?.taskId
			@startTime = timerData?.startTime
			utils.userData.set "timer", timerData, -> callback()

		getTaskWithTimerTitle: (callback) ->
			wrikeUtils.getTask @taskId, (task) ->
				taskTitle =
					if task?
						inactiveStatePrefixes =
							1: '!! COMPLETED: '
							2: '!! DEFERRED: '
							3: '!! CANCELLED: '
						(inactiveStatePrefixes[task.data["state"]] ? '') + task.data["title"]
					else
						"!! TASK NOT FOUND"

				callback taskTitle


	wrikeUtils =
		getCurrentUserId: -> w2.user.getUid()

		currentUserIsResponsibleForTask: (task) -> task.data["responsibleList"].indexOf(@getCurrentUserId()) >= 0

		getTask: (taskId, callback) -> Wrike.Task.get taskId, (task) -> callback task

		getCurrentTaskView: -> window.Ext.ComponentMgr.get ($('.taskView').attr 'id')

		getCurrentTask: -> @getCurrentTaskView()?["record"]

		onTaskViewRender: (callback) ->
			cb = (taskView) -> callback taskView["record"], taskView
			taskViewClass = window.w2.folders.info.task.View
			utils.aspect.before taskViewClass, "showRecord", ->	cb @

			currentTaskView = @getCurrentTaskView()
			if currentTaskView
				cb currentTaskView

		onTaskChange: (callback) ->
			utils.aspect.after Wrike.Task, "getChanges", (-> callback @)

	return {start}
