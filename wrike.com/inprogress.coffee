->
	utils = null
	inprogressTagText = "[In progress] "

	start = (utilities) ->
		utils = utilities

		wrikeUtils.onTaskViewRender drawInProgressCheckbox

		renderFilterPanel()

	drawInProgressCheckbox = (task, taskView) ->
		if not taskView.inProgressCheckbox?
			taskView.inProgressCheckbox = new WrikeCheckbox "In progress", (checked) ->
				currentTask = taskView["record"]
				currentTitle = currentTask.get 'title'
				currentTask.set 'title', (if checked then inprogressTagText + currentTitle else currentTitle.replace inprogressTagText, '')
				currentTask.save taskView.callback

		taskView.inProgressCheckbox.setEnabled wrikeUtils.currentUserIsResponsibleForTask task
		taskView.inProgressCheckbox.setChecked (task.get 'title').indexOf(inprogressTagText) >= 0

		$('td.info-importance').after taskView.inProgressCheckbox.contents

	renderFilterPanel = ->
		filterPanel = new WrikeFilterPanel 'In progress'
		filterPanel.addCheckbox new WrikeFilterCheckbox "In progress", inprogressTagText
		filterPanel.waitToRender()

	class WrikeCheckbox
		checkbox: null
		contents: null
		constructor: (text, onCheckedChange)->
			@contents = $("""<div style="padding-left:10px;"><div  class="x-form-check-wrap"  ><div class="x-form-checkbox-inner"><input type="checkbox" autocomplete="off" class=" x-form-checkbox x-form-field"></div><label for="ext-inprogress" class="x-form-cb-label">#{text}</label></div></div>""")
			@checkbox = @contents.find 'input'
			@form = @contents.find '.x-form-checkbox-inner'
			@checkbox.click =>
				onCheckedChange @isChecked()

		isChecked: -> @checkbox.is ":checked"
		setEnabled: (value)->
			if value
				@checkbox.removeAttr 'disabled'
			else
				@checkbox.attr 'disabled', 'disabled'
		setChecked: (value) ->
			if value
				@checkbox.attr 'checked', 'checked'
			else
				@checkbox.removeAttr 'checked'

			@form.toggleClass 'x-form-check-checked', value

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


