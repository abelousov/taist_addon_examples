
(function() {
  var createTimerButton, drawSelectedTask, start, taskWithTimerView, timer, utils, wrikeUtils;
  utils = null;
  start = function(utilities) {
    utils = utilities;
    wrikeUtils.onTaskChange(function() {
      return taskWithTimerView.render();
    });
    return timer.load(function() {
      wrikeUtils.onTaskViewRender(drawSelectedTask);
      return taskWithTimerView.render();
    });
  };
  drawSelectedTask = function(task, taskView) {
    if (taskView.taistTimerButton == null) {
      taskView.taistTimerButton = createTimerButton();
    }
    return taskView.taistTimerButton.render(task);
  };
  taskWithTimerView = {
    _getParent: function() {
      return $('.w2-actions-toolbar .x-toolbar-left-row');
    },
    _contentsId: 'taist-timetracker-currentTask',
    _getContentsContainer: function() {
      var contentsContainer;
      contentsContainer = this._getParent().find("#" + this._contentsId);
      if (contentsContainer.length === 0) {
        contentsContainer = $("<td id=\"" + this._contentsId + "\"></td>");
        this._getParent().append(contentsContainer);
      }
      return contentsContainer;
    },
    isVisible: function() {
      return this._getParent().length > 0;
    },
    render: function() {
      var setHtml,
        _this = this;
      if (this.isVisible()) {
        setHtml = function(htmlString) {
          return _this._getContentsContainer().html(htmlString);
        };
        if (timer.isStarted()) {
          return timer.getTaskWithTimerTitle(function(taskTitle) {
            return setHtml("<span id=\"taist-timetracker-currentCaption\">Current: </span><a href=\"https://www.wrike.com/open.htm?id=" + timer['taskId'] + "\" class=\"start\">" + taskTitle + "</a>");
          });
        } else {
          return setHtml('');
        }
      }
    }
  };
  createTimerButton = function() {
    return {
      render: function(task) {
        this._task = task;
        return this._redraw();
      },
      _redraw: function() {
        var icon, _ref;
        icon = (_ref = this.icons[this._getState()]) != null ? _ref : '';
        return this._getContainer().html(icon);
      },
      _getState: function() {
        if (wrikeUtils.currentUserIsResponsibleForTask(this._task)) {
          if (!timer.isStarted()) {
            return "start";
          } else if (timer.taskId === this._task.data["id"]) {
            return "stop";
          }
        }
      },
      _getContainer: function() {
        var container, containerClass, predecessor,
          _this = this;
        predecessor = $('td.info-tracking');
        containerClass = "taist-timetrack";
        container = predecessor.siblings("." + containerClass);
        if (container.length === 0) {
          container = $("<td></td>", {
            "class": containerClass,
            click: function() {
              return _this._onClick();
            }
          });
          predecessor.after(container);
        }
        return container;
      },
      _onClick: function() {
        var state,
          _this = this;
        state = this._getState();
        if (state === "start") {
          return timer.start(this._task, function() {
            _this._redraw();
            return taskWithTimerView.render();
          });
        } else if (state === "stop") {
          return this._openTimeRecordWindow();
        }
      },
      _openTimeRecordWindow: function() {
        var roundedHoursString, saveTimeButton, spentHours, spentMilliseconds,
          _this = this;
        spentMilliseconds = new Date().getTime() - timer.startTime;
        spentHours = spentMilliseconds / (1000 * 60 * 60);
        roundedHoursString = spentHours.toFixed(1);
        $('#taskview-tracking-link').click();
        $('.w3-input-element').children().first().next().val(roundedHoursString);
        $('.x-btn-plain-c').children().children();
        saveTimeButton = $('.actions').find("button");
        if (!(saveTimeButton.timetrackHandlerAdded != null)) {
          saveTimeButton.timetrackHandlerAdded = true;
          return saveTimeButton.bind('click', function() {
            return timer.stop(function() {});
          });
        }
      },
      icons: {
        start: '<img class="timer-icon" alt="Start timer" title="Start timer" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAA40lEQVQ4EZ2T0RGCMAyG/1TfdQNX0Q0cwRHoBDIBMAIrOIE4ghvoBvquhNRe7npcwRa4Etrm/y5pE5gC7t0yM5YMEgCD8JZv0wMN1/xCxmN+voyN2LMhPFaWigw9fARjBeFJjPJTczveGs/jAPVKAM0DAlDPOMn5dLqk1p+BzqYsYyeOV2OpI0v70C0tglAh/wzcZJQuokUA5QnkkpaCKiJ2EcClIEV36Gs+riPQyaUwd3VKAxDuco1F7BrnAVpI1XRFxgEJwngKvivLb8WNOvyzPgJtZ2np3HZ2ACsH1OYKNbIBKYWPOrHmye0AAAAASUVORK5CYII="/>',
        stop: '<img class="timer-icon" alt="Stop timer" title="Stop timer" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQCAYAAAAvf+5AAAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAAPklEQVQoFWNkKmT4wPCfgZ8BBBgZPv7t+y8AYjIXMaKIM8EVgWRhGrCwmUBixIBRhXhDaZgFDzBpwb2Lhw0Am8sRg1PD+GUAAAAASUVORK5CYII="/>'
      },
      _task: null,
      _timer: null
    };
  };
  timer = {
    taskId: null,
    startTime: null,
    load: function(callback) {
      var _this = this;
      return utils.userData.get("timer", function(error, timerData) {
        if (timerData != null) {
          return wrikeUtils.getTask(timerData.taskId, function(task) {
            if ((task != null) && !task["isDeleted"]) {
              _this.taskId = timerData.taskId;
              _this.startTime = timerData.startTime;
            }
            return callback();
          });
        } else {
          return callback();
        }
      });
    },
    isStarted: function() {
      return this.taskId != null;
    },
    stop: function(callback) {
      return this._save(null, callback);
    },
    start: function(task, callback) {
      return this._save({
        taskId: task.data.id,
        startTime: new Date().getTime()
      }, callback);
    },
    _save: function(timerData, callback) {
      this.taskId = timerData != null ? timerData.taskId : void 0;
      this.startTime = timerData != null ? timerData.startTime : void 0;
      return utils.userData.set("timer", timerData, function() {
        return callback();
      });
    },
    getTaskWithTimerTitle: function(callback) {
      return wrikeUtils.getTask(this.taskId, function(task) {
        var inactiveStatePrefixes, taskTitle, _ref;
        taskTitle = task != null ? (inactiveStatePrefixes = {
          1: '!! COMPLETED: ',
          2: '!! DEFERRED: ',
          3: '!! CANCELLED: '
        }, ((_ref = inactiveStatePrefixes[task.data["state"]]) != null ? _ref : '') + task.data["title"]) : "!! TASK NOT FOUND";
        return callback(taskTitle);
      });
    }
  };
  wrikeUtils = {
    getCurrentUserId: function() {
      return w2.user.getUid();
    },
    currentUserIsResponsibleForTask: function(task) {
      return task.data["responsibleList"].indexOf(this.getCurrentUserId()) >= 0;
    },
    getTask: function(taskId, callback) {
      return Wrike.Task.get(taskId, function(task) {
        return callback(task);
      });
    },
    getCurrentTaskView: function() {
      return window.Ext.ComponentMgr.get($('.taskView').attr('id'));
    },
    getCurrentTask: function() {
      var _ref;
      return (_ref = this.getCurrentTaskView()) != null ? _ref["record"] : void 0;
    },
    onTaskViewRender: function(callback) {
      var cb, currentTaskView, taskViewClass;
      cb = function(taskView) {
        return callback(taskView["record"], taskView);
      };
      taskViewClass = window.w2.folders.info.task.View;
      utils.aspect.before(taskViewClass, "showRecord", function() {
        return cb(this);
      });
      currentTaskView = this.getCurrentTaskView();
      if (currentTaskView) return cb(currentTaskView);
    },
    onTaskChange: function(callback) {
      return utils.aspect.after(Wrike.Task, "getChanges", (function() {
        return callback(this);
      }));
    }
  };
  return {
    start: start
  };
});
