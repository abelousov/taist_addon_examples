->
	utils = null
	start = (utilities) ->
		utils = utilities

		wrikeUtils.onTaskViewRender render

#		renderFilterPanel()

	render = (task, taskView) ->
		prepareStateButtons taskView
		taskView.stateMachine.applyCurrentState task

	prepareStateButtons = (taskView) ->
		if not taskView.stateMachine?
			stateMachine = taskView.stateMachine = new StateMachine taskView

			prevElement = $ '.wspace-task-importance-button'

			for state in stateMachine.allStates
				do (state) ->
					buttonClass = "approval-button-#{state.id}"
					newButtonContainer = $ """<div class="#{buttonClass}"></div>"""
					prevElement.after newButtonContainer
					prevElement = newButtonContainer

					button = new Ext.Button
						renderTo: newButtonContainer[0]
						text: state.buttonCaption
						handler: ->
							task = taskView.record

							utils.log "updating task: ", task

							stateMachine.applyState state, task, true

						style: "float: left;margin-left: 15px;"

					state.button = button

	renderFilterPanel = ->
		filterPanel = new WrikeFilterPanel 'Approval'
		for state in ApproveState.allStates
			filterCheckbox = new WrikeFilterCheckbox state.filterName, state.tagText
			filterPanel.addCheckbox filterCheckbox
		filterPanel.waitToRender()

	class StateMachine
		allStates: []
		_initialNextStateIds: "toApprove"
		_taskView: null

		constructor: (@_taskView)->
			@allStates.push new ApproveState("toApprove", "To approve", "To approve", "[ToApprove] ", ["declined", "approved"], "responsible", null)
			@allStates.push new ApproveState("declined", "Decline", "Declined", "[Declined] ", ["toApprove"], "author", null)
			@allStates.push new ApproveState("approved", "Approve", "Approved", "[Approved] ", [], "responsible", "1")

		applyCurrentState: (task) ->
			currentState = null
			for state in @allStates
				if state.isUsedBy task
					currentState = state

			@applyState currentState, task, false

		applyState: (currentState, task, needUpdate) ->
			if currentState? and needUpdate
				@_updateTaskWithState currentState, task
			nextStateIds = currentState?.nextStateIds ? @_initialNextStateIds
			for state in @allStates
				visible = nextStateIds.indexOf(state.id) >= 0 && (state.canBeSetOn task)
				state.button.setVisible visible

		_updateTaskWithState: (currentState, task) ->
			for state in @allStates
				state.removeFromTask task

			currentState.addToTask task

			task.save @_taskView.callback


	class ApproveState
		constructor: (@id, @buttonCaption, @filterName, @tagText, @nextStateIds, @availableFor, @newTaskState) ->

		isUsedBy: (task) -> (task.get "title").indexOf(@tagText) >= 0

		canBeSetOn: (task) ->
			return (@availableFor == "responsible" && wrikeUtils.currentUserIsResponsibleForTask task) || (@availableFor == "author" && wrikeUtils.currentUserIsAuthor task)

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

		getTask: (taskId, callback) -> Wrike.Task.get taskId, (task) -> callback task

		getCurrentTaskView: -> window.Ext.ComponentMgr.get ($('.w3-task-view').attr 'id')

		getCurrentTask: -> @getCurrentTaskView()?["record"]

		onTaskViewRender: (callback) ->
			callbackClosure = =>
				callback @getCurrentTask(), @getCurrentTaskView()

			liveEditorClass = w2.task.widget.liveeditor.View

			utils.aspect.after liveEditorClass, "onShowRecord", callbackClosure

			if @getCurrentTaskView()
				callbackClosure()

		onTaskChange: (callback) -> utils.aspect.after Wrike.Task, "getChanges", (-> callback @)

	return {start}
