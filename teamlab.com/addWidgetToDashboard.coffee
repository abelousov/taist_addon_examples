->
	taistApi = null

	start = (_taistApi) ->
		taistApi = _taistApi

		getOverdueTasks drawOverDueTasks

	getOverdueTasks = (callback) ->
		tasksRequest =
			filter:
				deadlineStop: (cleanTimeFromDate new Date).toISOString()
				status: "open"
				participant: getCurrentUserId()
				sortBy: 'deadline'
				sortOrder: 'ascending'

			success: -> callback arguments[1]

		window.Teamlab.getPrjTasks null, tasksRequest

	drawOverDueTasks = (tasks) ->
		overdueTasksUrl = "/products/projects/tasks.aspx#sortBy=deadline&sortOrder=ascending&tasks_responsible=#{getCurrentUserId()}&overdue=true"

		overdueTasksExist = tasks.length > 0

		widgetContainer = jQuery "<div style=\"text-align: left;\"></div>"

		headerColor =
			if overdueTasksExist
				"red"
			else
				"#3498db"

		widgetContainer.append """<a style="color: #{headerColor};" class="linkHeaderLightBig" href="#{overdueTasksUrl}">Overdue tasks: </a><br/>"""

		tasksContainer = jQuery '<div style="margin-left: 40px"></div>'
		widgetContainer.append tasksContainer

		if overdueTasksExist
			for task in tasks
				tasksContainer.append (getTaskLink task), '<br/>'

		else
			tasksContainer.append '<div style="font-style: italic">No task is overdue. Congrats!</div>'

		jQuery('.header-base-big').after widgetContainer

	getTaskLink = (task) ->
		taskUrl = "/products/projects/tasks.aspx?prjID=#{task.projectId}&id=#{task.id}"

		overdueDays = getDateOffsetFromNow task.deadline
		overdueDaysText =
			if overdueDays is 0
				'today'
			else if overdueDays is 1
				'yesterday'
			else
				overdueDays + ' days'

		overdueDaysHtml = "<span style=\"color: red; margin-left: 20px;\">#{overdueDaysText}</span>"

		taskTitleHtml = "<span style=\"color: #333;\">#{task.title}</span>"

		return "<div style=\"margin-top: 5px;\"><a style=\"font-weight: bold\" href=\"#{taskUrl}\">#{taskTitleHtml + overdueDaysHtml}</a></div>"

	getDateOffsetFromNow = (pastDate) ->
		today = cleanTimeFromDate new Date()
		cleanedPastDate = cleanTimeFromDate pastDate
		millisecondsInDay = 1000 * 60 * 60 * 24
		return (today - cleanedPastDate)/millisecondsInDay

	cleanTimeFromDate = (date) ->
		cleanedDate = new Date date
		for timepart in ['Hours', 'Minutes', 'Seconds', 'Milliseconds']
			cleanedDate['set' + timepart] 0

		return cleanedDate


	getCurrentUserId = -> window.ServiceFactory.profile.id

	return {start}
