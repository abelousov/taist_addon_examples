->
	utils = null
	buttonsContainer = null

	start = (utilities) ->
		utils = utilities

		wrikeUtils.onTaskViewRender render

#		renderFilterPanel()

	render = (task) ->
		if task?
			stateMachine = addStateMachine()
			stateMachine.task = task
			stateMachine.applyCurrentState()

	addStateMachine = ->
		stateMachine = new StateMachine()
		buttonsContainerClass = "taist-stateButtonsContainer"
		buttonsContainer = $ '.' + buttonsContainerClass
		if buttonsContainer.length is 0
			utils.log 'buttons container doesnot exist, creating new one'
			buttonsContainer = $ '<div class="#{buttonsContainerClass}"></div>'
			prevElement = $('.wspace-task-importance-button')
			prevElement.after buttonsContainer
			utils.log 'inserted buttons container: ', prevElement, buttonsContainer, buttonsContainer.parent()
		else
			utils.log('emptying buttons container: ', buttonsContainer)
			buttonsContainer.empty()
			utils.log('emptying result: ', buttonsContainer)

		for state in stateMachine.allStates
			do (state) ->
				button = createButton state, stateMachine
				buttonsContainer.append button
				state.button = button

		return stateMachine

	createButton = (state, stateMachine) ->
		button = $("<a class=\"wrike-button-base x-btn-noicon\" style=\"width: auto; float: left; margin-left: 15px;\">" + state.buttonCaption + "</a>")
		button.click ->
			stateMachine.changeState state
			return false
		return button

	renderFilterPanel = ->
		filterPanel = new WrikeFilterPanel 'Approval'
		for state in ApproveState.allStates
			filterCheckbox = new WrikeFilterCheckbox state.filterName, state.tagText
			filterPanel.addCheckbox filterCheckbox
		filterPanel.waitToRender()

	class StateMachine
		allStates: []
		_initialNextStateIds: "toApprove"
		task: null

		constructor: ->
			@allStates.push new ApproveState("toApprove", "To approve", "To approve", "[ToApprove] ", ["declined", "approved"], "responsible", null)
			@allStates.push new ApproveState("declined", "Decline", "Declined", "[Declined] ", ["toApprove"], "author", null)
			@allStates.push new ApproveState("approved", "Approve", "Approved", "[Approved] ", [], "responsible", "1")

		applyCurrentState: ->
			currentState = null
			for state in @allStates
				if state.isUsedBy @task
					currentState = state

			@_applyState currentState, false

		changeState: (state) -> @_applyState state, true

		_applyState: (newState, needUpdate) ->
			if needUpdate
				@_updateTaskWithState newState

			nextStateIds = newState?.nextStateIds ? @_initialNextStateIds
			for state in @allStates
				visible = nextStateIds.indexOf(state.id) >= 0 && (state.canBeSetOn @task)
				state.button.toggle visible

		_updateTaskWithState: (currentState) ->
			for state in @allStates
				state.removeFromTask @task

			currentState.addToTask @task

			@task.save()


	class ApproveState
		nextStateIds: null
		availableFor: null
		button: null
		constructor: (@id, @buttonCaption, @filterName, @tagText, @nextStateIds, @availableFor, @newTaskState) ->

		isUsedBy: (task) -> (task.get "title").indexOf(@tagText) >= 0

		canBeSetOn: (task) ->
			if @availableFor is "responsible"
				wrikeUtils.currentUserIsResponsibleForTask task
			else if @availableFor is "author"
				wrikeUtils.currentUserIsAuthor task
			else
				null

		addToTask: (task) ->
			task.set 'title', @tagText + (task.get 'title')
			if @newTaskState?
				task.set "state", @newTaskState


		removeFromTask: (task) -> task.set 'title', ((task.get 'title').replace @tagText, '')

	class WrikeFilterCheckbox
		constructor: (@caption, @tagText) ->
			@contents = $ """<div style="padding-left:10px;"></div>"""
			container = $ """<div class="x-form-check-wrap"></div>"""

			form = $ "<div></div>",
				class: "x-form-checkbox-inner"

			@checkbox = $ "<input>"
				type: "checkbox"
				autocomplete: "off"
				class: "x-form-checkbox x-form-field",
				click: =>
					form.toggleClass "x-form-check-checked"
					@updateQuery()

			label = $ "<label></label>",
				class: "x-form-cb-label"
				text: @caption

			form.append @checkbox
			container.append form, label
			@contents.append container

		updateQuery: ->
			query = Wrike.env.FILTERS.get 'text'
			if @checked()
				query.push @tagText
			else
				query = (text for text in query when text != @tagText)
			BUS.fireEvent 'list.filter.changed',
				text: query

		checked: -> @checkbox.is ":checked"

	class WrikeFilterPanel
		template: null
		checkboxContainer: null
		_parentClass: 'w2-folder-listview-filters-filterspane-body'
		_getParent: -> ($ '.' + @_parentClass)
		constructor: (title)->
			@contents = $("""<div class="w2-folder-listview-filters-filterpane">
																																					<div class="w2-folder-listview-filters-filterpane-title x-unselectable">#{title}</div>
																																					<div  class="x-form-check-group x-column-layout-ct x-form-field w2-folder-listview-filters-filterpane-chgroup">
																																						<div class="x-column-inner" id="ext-gen1145" style="width: 170px;">
																																							<div  class=" x-column" style="width: 170px;">
																																								<div class="x-form-item  x-hide-label" tabindex="-1"></div>
																																								<div class="x-form-clear-left"></div>
																																							</div>
																																						</div>
																																					</div>
																																				</div>""")
			@checkboxContainer = @contents.find ".x-form-item"

		waitToRender: ->
			that = @
			utils.aspect.after Ext.Panel, "afterRender", ->
				if @bodyCssClass == that._parentClass
					that._render()

			@_render()

		_render: -> @_getParent().append @contents

		addCheckbox: (checkbox) -> @checkboxContainer.append checkbox.contents

	wrikeUtils =
		getCurrentUserId: -> w2.user.getUid()

		currentUserIsResponsibleForTask: (task) -> task.data["responsibleList"].indexOf(@getCurrentUserId()) >= 0

		currentUserIsAuthor: (task) -> (task.get 'author') is @getCurrentUserId()

		getCurrentTaskView: -> window.Ext.ComponentMgr.get ($('.w3-task-view').attr 'id')

		getCurrentTask: -> @getCurrentTaskView()?["record"]

		onTaskViewRender: (callback) ->
			listenerName = "beforesetrecord"
			listenersInPrototype = w2.task.View.prototype.xlisteners

			utils.aspect.after listenersInPrototype, listenerName, (view, task) ->
				if task?
					task.load (loadedTask) ->
						utils.log 'set task: ', loadedTask.data.title
						callback loadedTask, view
				else
					utils.log 'unset task'
					return callback null, view

			[currentTask, currentTaskView] = [@getCurrentTask(), @getCurrentTaskView()]

			if currentTask? and currentTaskView?

				#manually replace already initialized listener in existing view
				#better would be just to override it in prototype before any view is created - more early addon launch is required
				enhancedListener = listenersInPrototype[listenerName]
				currentViewListeners = currentTaskView.events[listenerName].listeners[0]
				currentViewListeners.fn = currentViewListeners.fireFn = enhancedListener

				callback currentTask, currentTaskView

		onTaskChange: (callback) -> utils.aspect.after Wrike.Task, "getChanges", (-> callback @)

	return {start}
