->
	start: (utils) ->
		utils.dev.logMethodCalls window.Teamlab, "Teamlab"
		utils.dev.logMethodCalls window.ServiceManager, "ServiceManager"

		myOverdueTasksFilter =
			deadlineStop: (new Date).toISOString()
			status: "open"
			participant: window.ServiceFactory.profile.id

		window.Teamlab.getPrjTasks null, {filter: myOverdueTasksFilter, success: (->
			window.taskList = arguments[1]
			console.log 'taskList: ', arguments
		)}

		originalDrawTasksFunctionForReference = (tasksInfo, tasksList) ->
			jq("#SubTasksBody").height("auto");
			jq("#SubTasksBody .taskSaving").hide();
			clearTimeout(ao);
			X = false;
			y();
			jq("#SubTasksBody .taskList").html("");
			jq("#showNextTaskProcess").hide();
			jq("#SubTasksBody .taskList").height("auto");
			if (tasksList.length)
				jq.tmpl("projects_taskListItemTmpl", tasksList).appendTo(".taskList")

			if (!m)
				jq("#SubTasksBody .choose.project span").html(jq("#SubTasksBody .choose.project").attr("choose"));
				jq("#SubTasksBody .choose.project").attr("value", "")

			LoadingBanner.hideLoading();
			r = tasksInfo.__total : 0;
			aq();
			p(tasksList.length);
			ASC.Projects.TasksManager.resize()
