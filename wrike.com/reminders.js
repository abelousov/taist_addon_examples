
(function() {
  var Reminder, calendarUtils, container, createCalendarSelect, createNotificationCheck, createTimeSelect, draw, drawAuthorization, drawReminderEditControl, drawReminderView, drawRemindersContainer, icons, reminder, removeRemindersContainer, start, updateReminderForTask, utils, wrikeUtils;
  utils = null;
  container = null;
  reminder = null;
  start = function(utilities) {
    utils = utilities;
    return calendarUtils.init(function() {
      wrikeUtils.onTaskViewRender(function(task) {
        return draw(task);
      });
      return wrikeUtils.onTaskChange(function(updatedTask) {
        return updateReminderForTask(updatedTask);
      });
    });
  };
  draw = function(task) {
    var _this = this;
    removeRemindersContainer();
    reminder = new Reminder(task);
    if (!wrikeUtils.currentUserIsResponsibleForTask(task) || !reminder.canBeSet()) {
      return;
    }
    drawRemindersContainer();
    if (!calendarUtils.authorized()) {
      return drawAuthorization();
    } else {
      return reminder.load(function() {
        return drawReminderView();
      });
    }
  };
  Reminder = (function() {

    Reminder._calendarsList = null;

    Reminder.prototype._reminderData = null;

    Reminder.prototype._defaultSettings = null;

    function Reminder(_task) {
      this._task = _task;
    }

    Reminder.prototype.load = function(callback) {
      var _this = this;
      return Reminder._loadCalendars(function() {
        return _this._loadReminderData(function() {
          return callback();
        });
      });
    };

    Reminder.prototype.exists = function() {
      return this._reminderData != null;
    };

    Reminder._loadCalendars = function(callback) {
      var _this = this;
      if (!(this._calendarsList != null)) {
        return calendarUtils.loadCalendars(function(calendarsList) {
          _this._calendarsList = calendarsList;
          return callback();
        });
      } else {
        return callback();
      }
    };

    Reminder.prototype._loadReminderData = function(callback) {
      var _this = this;
      this._reminderData = null;
      return utils.userData.get("defaultSettings", function(error, defaultSettingsData) {
        _this._defaultSettings = defaultSettingsData;
        return utils.userData.get(_this._task.data.id, function(error, existingReminderData) {
          var calendarId, eventId;
          eventId = existingReminderData != null ? existingReminderData.eventId : void 0;
          calendarId = existingReminderData != null ? existingReminderData.calendarId : void 0;
          if (!(eventId != null) || !(calendarId != null)) {
            return callback();
          } else {
            return calendarUtils.getEvent(eventId, calendarId, function(event) {
              var eventIsActual;
              eventIsActual = (event != null) && event.status !== "cancelled";
              if (eventIsActual) {
                _this._reminderData = {
                  event: event,
                  calendarId: calendarId
                };
              }
              return callback();
            });
          }
        });
      });
    };

    Reminder.prototype.canBeSet = function() {
      return this._getRawBaseValue() != null;
    };

    Reminder.prototype._getBaseDateTime = function() {
      return new Date(this._getRawBaseValue());
    };

    Reminder.prototype._getRawBaseValue = function() {
      var _ref;
      return (_ref = this._task.data["startDate"]) != null ? _ref : this._task.data["finishDate"];
    };

    Reminder.prototype.getDisplayData = function() {
      var addLeadingZero, currentSettings, hours, hoursRange, minutes, minutesRange, notification, reminderTime, usedNotifications, _i, _len, _ref, _ref2, _ref3, _ref4, _ref5;
      _ref = this.exists() ? (addLeadingZero = function(number) {
        if (number < 10) {
          return "0" + number;
        } else {
          return number;
        }
      }, reminderTime = new Date(this._reminderData.event.start.dateTime), [addLeadingZero(reminderTime.getHours()), addLeadingZero(reminderTime.getMinutes())]) : ['08', '00'], hours = _ref[0], minutes = _ref[1];
      hoursRange = ['06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'];
      minutesRange = ['00', '15', '30', '45'];
      currentSettings = this._reminderData != null ? {
        calendardId: this._reminderData.calendarId,
        reminders: this._reminderData.event.reminders
      } : this._defaultSettings;
      usedNotifications = {};
      _ref4 = (_ref2 = currentSettings != null ? (_ref3 = currentSettings.reminders) != null ? _ref3.overrides : void 0 : void 0) != null ? _ref2 : [];
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        notification = _ref4[_i];
        usedNotifications[notification.method] = true;
      }
      return {
        hours: hours,
        minutes: minutes,
        hoursRange: hoursRange,
        minutesRange: minutesRange,
        usedNotifications: usedNotifications,
        calendars: Reminder._calendarsList,
        currentCalendar: (_ref5 = currentSettings != null ? currentSettings.calendarId : void 0) != null ? _ref5 : Reminder._calendarsList[0].id
      };
    };

    Reminder.prototype["delete"] = function(callback) {
      var _this = this;
      if (this.exists()) {
        return calendarUtils.deleteEvent(this._reminderData.event.id, this._reminderData.calendarId, function() {
          _this._reminderData = null;
          return callback();
        });
      }
    };

    Reminder.prototype.set = function(hours, minutes, calendarId, useSms, useEmail, callback) {
      var eventStartDate, notifications;
      eventStartDate = this._getBaseDateTime();
      eventStartDate.setHours(hours, minutes);
      notifications = [];
      if (useSms) notifications.push("sms");
      if (useEmail) notifications.push("email");
      return this._setByDateTime(eventStartDate, calendarId, notifications, callback);
    };

    Reminder.prototype._setByDateTime = function(eventStartDate, newCalendarId, notifications, callback) {
      var eventData, method, newCallback, _i, _len, _ref, _ref2,
        _this = this;
      eventData = (_ref = (_ref2 = this._reminderData) != null ? _ref2.event : void 0) != null ? _ref : {};
      eventData.summary = this._task.data["title"];
      eventData.start = {
        dateTime: eventStartDate
      };
      eventData.end = {
        dateTime: eventStartDate
      };
      eventData.description = "Task link: https://www.wrike.com/open.htm?id=" + this._task.data.id;
      if (notifications != null) {
        eventData.reminders = {
          useDefault: false,
          overrides: []
        };
        for (_i = 0, _len = notifications.length; _i < _len; _i++) {
          method = notifications[_i];
          eventData.reminders.overrides.push({
            method: method,
            minutes: 0
          });
        }
      }
      newCallback = function(newEvent) {
        return _this._save(newEvent, newCalendarId, callback);
      };
      if (this._reminderData != null) {
        return calendarUtils.changeEvent(this._reminderData.event.id, this._reminderData.calendarId, newCalendarId, eventData, newCallback);
      } else {
        return calendarUtils.createEvent(newCalendarId, eventData, newCallback);
      }
    };

    Reminder.prototype.updateForTask = function() {
      var reminderDateTime, startDateTime;
      if (this.exists()) {
        startDateTime = this._task.data["startDate"];
        reminderDateTime = this._getBaseDateTime();
        startDateTime.setHours(reminderDateTime.getHours(), reminderDateTime.getMinutes());
        return this._setByDateTime(startDateTime, this._reminderData.calendarId, null, function() {});
      }
    };

    Reminder.prototype._save = function(newEvent, calendarId, callback) {
      var _this = this;
      this._reminderData = {
        event: newEvent,
        calendarId: calendarId
      };
      this._defaultSettings = {
        calendarId: calendarId,
        reminders: newEvent.reminders
      };
      return utils.userData.set(this._task.data.id, {
        eventId: newEvent.id,
        calendarId: calendarId
      }, function() {
        return utils.userData.set("defaultSettings", _this._defaultSettings, function() {
          return callback();
        });
      });
    };

    return Reminder;

  })();
  drawAuthorization = function() {
    var authButton;
    authButton = $('<button>', {
      text: 'Authorize Google Calendar',
      click: function() {
        calendarUtils.authorize(function() {
          var currentTask;
          currentTask = wrikeUtils.getCurrentTask();
          if (currentTask != null) return draw(currentTask);
        });
        return false;
      }
    });
    return container.append(authButton);
  };
  drawRemindersContainer = function() {
    var taskDurationSpan;
    taskDurationSpan = $('.x-duration');
    container = $('<span class="taist-reminders-container"></span>');
    return taskDurationSpan.after(container);
  };
  removeRemindersContainer = function() {
    if (container != null) {
      container.remove();
      return container = null;
    }
  };
  drawReminderEditControl = function() {
    var calendarSelect, cancelLink, displayData, emailCheck, hoursSelect, minutesSelect, reminderEditControl, setLink, smsCheck;
    container.html('');
    reminderEditControl = $('<span></span>');
    displayData = reminder.getDisplayData();
    smsCheck = createNotificationCheck("Sms", "sms", displayData);
    emailCheck = createNotificationCheck("E-mail", "email", displayData);
    hoursSelect = createTimeSelect(displayData.hoursRange, displayData.hours);
    minutesSelect = createTimeSelect(displayData.minutesRange, displayData.minutes);
    setLink = $('<a></a>', {
      text: "Set",
      click: function() {
        var useEmail, useSms;
        useSms = smsCheck.check.is(':checked');
        useEmail = emailCheck.check.is(':checked');
        return reminder.set(hoursSelect.val(), minutesSelect.val(), calendarSelect.val(), useSms, useEmail, function() {
          return drawReminderView();
        });
      }
    });
    cancelLink = $("<a></a>", {
      text: 'Cancel',
      click: function() {
        return drawReminderView();
      }
    });
    calendarSelect = createCalendarSelect(displayData.calendars, displayData.currentCalendar);
    reminderEditControl.append(icons.reminderExists, ': ', hoursSelect, '-', minutesSelect, ' ', smsCheck.check, smsCheck.label, ' ', emailCheck.check, emailCheck.label, ' ', calendarSelect, ' ', setLink, ' / ', cancelLink);
    return container.append(reminderEditControl);
  };
  createNotificationCheck = function(caption, id, displayData) {
    return {
      check: $('<input>', {
        type: "checkbox",
        checked: displayData.usedNotifications[id],
        id: "taist-reminder-" + id
      }),
      label: $("<label for=\"Taist-reminder-" + id + "\">" + caption + "</label>")
    };
  };
  createTimeSelect = function(timeValues, currentValue) {
    var closestValue, option, timeSelect, timeValue, _i, _j, _len, _len2;
    closestValue = timeValues[0];
    for (_i = 0, _len = timeValues.length; _i < _len; _i++) {
      timeValue = timeValues[_i];
      if (timeValue <= currentValue) closestValue = timeValue;
    }
    timeSelect = $('<select></select>');
    for (_j = 0, _len2 = timeValues.length; _j < _len2; _j++) {
      timeValue = timeValues[_j];
      option = $('<option></option>', {
        text: timeValue,
        val: timeValue,
        selected: timeValue === closestValue
      });
      timeSelect.append(option);
    }
    return timeSelect;
  };
  createCalendarSelect = function(calendarsList, currentCalendarId) {
    var calendar, calendarSelect, _i, _len;
    calendarSelect = $('<select></select>');
    for (_i = 0, _len = calendarsList.length; _i < _len; _i++) {
      calendar = calendarsList[_i];
      calendarSelect.append($('<option></option>', {
        text: calendar.summary,
        val: calendar.id,
        selected: currentCalendarId === calendar.id
      }));
    }
    return calendarSelect;
  };
  drawReminderView = function() {
    var deleteLink, displayData, editLink, iconHtml, linkText;
    container.html('');
    linkText = null;
    iconHtml = null;
    if (reminder.exists()) {
      displayData = reminder.getDisplayData();
      iconHtml = icons.reminderExists;
      linkText = "<span class=\"taist-reminders-linkText\">" + displayData.hours + ":" + displayData.minutes;
    } else {
      iconHtml = icons.noReminder;
      linkText = "";
    }
    editLink = $("<a></a>", {
      click: function() {
        return drawReminderEditControl();
      },
      style: "border-bottom-style:none;"
    });
    editLink.append(iconHtml, linkText);
    container.append(editLink);
    if (reminder.exists()) {
      deleteLink = $('<a></a>', {
        text: 'X',
        click: function() {
          return reminder["delete"](function() {
            return drawReminderView();
          });
        },
        title: 'Delete'
      });
      return container.append(' (', deleteLink, ')');
    }
  };
  updateReminderForTask = function(task) {
    var reminderToUpdate;
    reminderToUpdate = new Reminder(task);
    return reminderToUpdate.load(function() {
      return reminderToUpdate.updateForTask();
    });
  };
  calendarUtils = {
    _client: null,
    _auth: null,
    _api: null,
    _authorized: false,
    init: function(callback) {
      var jsonpCallbackName,
        _this = this;
      jsonpCallbackName = 'calendarUtilsInitAfterApiLoad';
      window[jsonpCallbackName] = function() {
        delete window[jsonpCallbackName];
        return _this._waitForGapiAndInit(callback);
      };
      return $('body').append("<script src=\"https://apis.google.com/js/client.js?onload=" + jsonpCallbackName + "\"></script>");
    },
    _waitForGapiAndInit: function(callback) {
      var gapi,
        _this = this;
      gapi = window["gapi"];
      this._client = gapi.client;
      this._auth = gapi.auth;
      this._client.setApiKey('AIzaSyCLQdexpRph5rbV4L3V_9i0rXRRNiib304');
      return window.setTimeout((function() {
        return _this._getExistingAuth(callback);
      }), 0);
    },
    _getExistingAuth: function(callback) {
      return this._getAuth(true, callback);
    },
    authorize: function(callback) {
      return this._getAuth(false, callback);
    },
    _getAuth: function(useExistingAuth, callback) {
      var authOptions,
        _this = this;
      authOptions = {
        client_id: '181733347279',
        scope: 'https://www.googleapis.com/auth/calendar',
        immediate: useExistingAuth
      };
      return this._auth.authorize(authOptions, function(authResult) {
        _this._authorized = authResult && !(authResult.error != null);
        if (_this._authorized) {
          return _this._loadCalendarApi(callback);
        } else {
          return callback();
        }
      });
    },
    _loadCalendarApi: function(callback) {
      var _this = this;
      return this._client.load("calendar", "v3", function() {
        _this._api = _this._client["calendar"];
        return callback();
      });
    },
    authorized: function() {
      return this._authorized;
    },
    loadCalendars: function(callback) {
      var request,
        _this = this;
      request = this._api["calendarList"].list({
        minAccessRole: "writer",
        showHidden: true
      });
      return request.execute(function(response) {
        return callback(response.items);
      });
    },
    getEvent: function(eventId, calendarId, callback) {
      return this._accessEvent("get", {
        calendarId: calendarId,
        eventId: eventId
      }, callback);
    },
    deleteEvent: function(eventId, calendarId, callback) {
      return this._accessEvent("delete", {
        calendarId: calendarId,
        eventId: eventId
      }, callback);
    },
    changeEvent: function(eventId, currentCalendarId, newCalendarId, eventData, callback) {
      var _this = this;
      utils.log("changing: ", arguments);
      return this._accessEvent("update", {
        resource: eventData,
        calendarId: currentCalendarId,
        eventId: eventId
      }, function(newEvent) {
        if (currentCalendarId !== newCalendarId) {
          return _this._moveEvent(eventId, currentCalendarId, newCalendarId, callback);
        } else {
          return callback(newEvent);
        }
      });
    },
    createEvent: function(calendarId, eventData, callback) {
      return this._accessEvent("insert", {
        calendarId: calendarId,
        resource: eventData
      }, callback);
    },
    _moveEvent: function(eventId, currentCalendarId, newCalendarId, callback) {
      utils.log("moving: ", arguments);
      return this._accessEvent("move", {
        calendarId: currentCalendarId,
        destination: newCalendarId,
        eventId: eventId
      }, callback);
    },
    _accessEvent: function(method, params, callback) {
      return this._api.events[method](params).execute(function(eventOrResponse) {
        if (eventOrResponse.error != null) {
          return utils.error("couldn't " + method + " event: ", params, eventOrResponse.error);
        } else {
          return callback(eventOrResponse);
        }
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
      if (currentTaskView != null) return cb(currentTaskView);
    },
    onTaskChange: function(callback) {
      return utils.aspect.after(Wrike.Task, "getChanges", (function() {
        return callback(this);
      }));
    }
  };
  icons = {
    noReminder: '<img class="taist-reminders-reminder-icon" title="Add reminder" alt="Add reminder" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAB0ElEQVRIDa1W23HCMBCMTf7jDqIOcDqgA1pwKsAMj2++GRigglBC6EAdBDogHUABQHYZiZHkkzFJNCMknXb3dHeycXK5XJ6atOFwuASuZ7Cr2WxWNuGlTUDE4CDKYt25tcXG5F4E4/E4P51OkyRJuq4IeJtWqzWZTqdb1x7Oax0MBoMCwh8hyV3D0ft8Pl+7NncedcCTn8/nL4B36G2XFM7TNH2LRRKtAdMCIYpr9NpmsCIm6oA5R/8Ey94cUYDGsD4uUHQwGo06BCG/mQuum1tOiBEdIPc5gN9wwLFRM5wKVnSAkHOI7zGqCiNiIEfaEh0AmIOwxfgqkSK2hxzUXsuIA5FTiSBWrIioZ5a4FQcolgLriJ557AYLw/WQ3pPc7/czvF/2KLA2BRbD9hT8xREPnVosFgdrvkVgxDU27Oaj4tR8wQE1tbhguznAxhJrhdNvcfrudfd3P22jdWUnZVkyLRqrNsQ3fxR3j7RDujqMgOEo7vyjOOUUepaiIHtMCnS+Of+rUaugtnSLOoiE/wUcGd29Yu+Q2gP+EzTrh7Ro9xbxjXm3s04hTrKFGK6fm+QEl2CCr4qei4VthXXp2qS5lyIJYG3ms6Uw63XTz5YfqiH1WdCp6QMAAAAASUVORK5CYII=" />',
    reminderExists: '<img class="taist-reminders-reminder-icon" title="Reminder set at" alt="Reminder set at" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAACf2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICAgICA8ZGM6dGl0bGU+CiAgICAgICAgICAgIDxyZGY6U2VxPgogICAgICAgICAgICAgICA8cmRmOmxpIHhtbDpsYW5nPSJ4LWRlZmF1bHQiPmdseXBoaWNvbnM8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ1M2IChNYWNpbnRvc2gpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgopxlZkAAAB5klEQVRIDa1W3W3CMBC+Qy1UKlXpBM0G0A3YoCuEl/48wQiMAE+t+gIjtBtkg8IGdIJSCalVEFw/OxBwck5SqZYi+z5/9519PlthEaEqjR+aIxLpWy7zWJ5Xgyp+tSoky9lKkHKPxymoD7hsB3zX7BDJkJhuHQmhNyIeystq5uAZozAAxENimWR8XFO4hyBTFzxY3gB25SzvoM7xtQ8uykj4xreTgjNAWow4c6RIZiDLzWCJ6Q+Q5Pw1rRzVfQdmz+eIqwbgx4uu5TC3jriFw9Qnw1ID0HaDyqEPEjJ9tZb45Lh6AGII8wLlGeQ8vIDxyTdPAKycaQb6dd7Fi/wpQHFZ6jFUn9wOfIela7qo5psLQBuTd/5CebZc9wqW9XV5zk3m3lWL6usFxCOcAQKV3GBXCxYWFp8GMvlc7qfSHSTicYTK2U+qOd076r1cUj2OrNaOkAbAxAgrCFD7s9zLqav50HailUwzhS2kxawc6TBPcMG19yl68DnF9W6Nzn5wmBxY0v+JQ44Do12Tp+8F8h5S8iyj+5eGJ15Co61UUdxFiA5WgN6WatlhQ4yX4EbwmyEt0XEVoSKl9DPnlOVpWJZj7BNELW+N9ZDvz/sOscFj2AMHUwwnRcp8CiW/LRRagGla9bflF7nn2hBRMZnFAAAAAElFTkSuQmCC">'
  };
  return {
    start: start
  };
});
