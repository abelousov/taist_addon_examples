(function () {
	return {
		start: function (utils) {
			var myOverdueTasksFilter;
			utils.dev.logMethodCalls(window.Teamlab, "Teamlab");
			utils.dev.logMethodCalls(window.ServiceManager, "ServiceManager");
			myOverdueTasksFilter = {
				deadlineStop: (new Date).toISOString(),
				status: "open",
				participant: window.ServiceFactory.profile.id
			};
			return window.Teamlab.getPrjTasks(null, {
				filter: myOverdueTasksFilter,
				success: function () {
					return console.log('tasks: ', arguments);
				}
			});
		}
	};
});
