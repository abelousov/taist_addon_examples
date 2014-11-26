Addon is created as an example of usage of original website code:

* user id is retrieved from `window.ServiceFactory.profile.id`
* tasks are retrieved using `window.Teamlab.getPrjTasks`:

```javascript
getOverdueTasks = function(callback) {
    var tasksRequest;
    tasksRequest = {
      filter: {
        deadlineStop: (cleanTimeFromDate(new Date)).toISOString(),
        status: "open",
        participant: getCurrentUserId(),
        sortBy: 'deadline',
        sortOrder: 'ascending'
      },
      success: function() {
        return callback(arguments[1]);
      }
    };
    return window.Teamlab.getPrjTasks(null, tasksRequest);
  };
``` 
