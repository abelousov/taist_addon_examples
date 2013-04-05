->
	utils = null
	start = (utilities) ->
		utils = utilities

		initStates()

		wrikeUtils.onTaskViewRender render
		renderFilterPanel()

	render = (task, taskView) ->
		prepareStateButtons taskView
		ApproveState.applyCurrentState task

	initStates = ->
		new ApproveState("toApprove", "To approve", "To approve", "[ToApprove] ", ["declined", "approved"], "responsible", null)
		new ApproveState("declined", "Decline", "Declined", "[Declined] ", ["toApprove"], "author", null)
		new ApproveState("approved", "Approve", "Approved", "[Approved] ", [], "responsible", "1")
		ApproveState.initialNextStateIds = "toApprove"

	prepareStateButtons = (taskView) ->
		if not taskView.taistButtonsPrepared?
			prevElement = $ 'td.info-importance'
			for state in ApproveState.allStates
				do (state) ->
					newButtonContainer = $ """<td class="approval-button-#{state.id}"></td>"""
					prevElement.after newButtonContainer
					prevElement = newButtonContainer

					button = new Ext.Button
						injectTo: "td.approval-button-#{state.id}"
						text: state.buttonCaption
						handler: -> state.applyTo taskView
						style: "float: left;margin-left: 15px;"

					state.button = button
					taskView.add button
					utils.log "button added; state = #{state.id},", state

			taskView.prepareComponents()

			utils.log "all states after buttons prepared: ", ApproveState.allStates
			taskView.taistButtonsPrepared = true

	renderFilterPanel = ->
		filterPanel = new WrikeFilterPanel 'Approval'
		for state in ApproveState.allStates
			filterCheckbox = new WrikeFilterCheckbox state.filterName, state.tagText
			filterPanel.addCheckbox filterCheckbox
		filterPanel.waitToRender()

	class ApproveState
		@allStates: []
		@initialNextStateIds: null
		@applyCurrentState: (task) ->
			nextStateIds = null
			for state in @allStates
				if state.isUsedBy task
					nextStateIds = state.nextStateIds

			nextStateIds ?= @initialNextStateIds

			@renderNextStateButtons nextStateIds, task

		@renderNextStateButtons: (nextStateIds, task) ->
			utils.log "all states before rendering: ", @allStates
			for state in @allStates
				visible = nextStateIds.indexOf(state.id) >= 0 && (state.canBeSetOn task)
				state.button.setVisible visible


		constructor: (@id, @buttonCaption, @filterName, @tagText, @nextStateIds, @availableFor, @newTaskState) ->
			ApproveState.allStates.push @
			utils.log "new state created: ", @, "all states: ", ApproveState.allStates
		isUsedBy: (task) -> (task.get "title").indexOf(@tagText) >= 0

		canBeSetOn: (task) ->
			return (@availableFor == "responsible" && wrikeUtils.currentUserIsResponsibleForTask task) || (@availableFor == "author" && wrikeUtils.currentUserIsAuthor task)

		applyTo: (taskView) ->
			task = taskView["record"]
			cleanedTitle = task.get "title"
			for state in ApproveState.allStates
				cleanedTitle = cleanedTitle.replace state.tagText, ''

			task.set "title", @tagText + cleanedTitle

			if @newTaskState?
				task.set("state", @newTaskState)

			task.save(taskView.callback)

			@render task

		render: (task) ->
			ApproveState.renderNextStateButtons @nextStateIds, task

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

	return {start}
