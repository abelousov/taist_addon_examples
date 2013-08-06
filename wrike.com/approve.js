
(function() {
  var ApproveState, WrikeFilterCheckbox, WrikeFilterPanel, initStates, prepareStateButtons, render, renderFilterPanel, start, utils, wrikeUtils;
  utils = null;
  start = function(utilities) {
    utils = utilities;
    initStates();
    wrikeUtils.onTaskViewRender(render);
    return renderFilterPanel();
  };
  render = function(task, taskView) {
    prepareStateButtons(taskView);
    return ApproveState.applyCurrentState(task);
  };
  initStates = function() {
    new ApproveState("toApprove", "To approve", "To approve", "[ToApprove] ", ["declined", "approved"], "responsible", null);
    new ApproveState("declined", "Decline", "Declined", "[Declined] ", ["toApprove"], "author", null);
    new ApproveState("approved", "Approve", "Approved", "[Approved] ", [], "responsible", "1");
    return ApproveState.initialNextStateIds = "toApprove";
  };
  prepareStateButtons = function(taskView) {
    var prevElement, state, _fn, _i, _len, _ref;
    if (!(taskView.taistButtonsPrepared != null)) {
      prevElement = $('td.info-importance');
      _ref = ApproveState.allStates;
      _fn = function(state) {
        var button, newButtonContainer;
        newButtonContainer = $("<td class=\"approval-button-" + state.id + "\"></td>");
        prevElement.after(newButtonContainer);
        prevElement = newButtonContainer;
        button = new Ext.Button({
          injectTo: "td.approval-button-" + state.id,
          text: state.buttonCaption,
          handler: function() {
            return state.applyTo(taskView);
          },
          style: "float: left;margin-left: 15px;"
        });
        state.button = button;
        taskView.add(button);
        return utils.log("button added; state = " + state.id + ",", state);
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        _fn(state);
      }
      taskView.prepareComponents();
      utils.log("all states after buttons prepared: ", ApproveState.allStates);
      return taskView.taistButtonsPrepared = true;
    }
  };
  renderFilterPanel = function() {
    var filterCheckbox, filterPanel, state, _i, _len, _ref;
    filterPanel = new WrikeFilterPanel('Approval');
    _ref = ApproveState.allStates;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      state = _ref[_i];
      filterCheckbox = new WrikeFilterCheckbox(state.filterName, state.tagText);
      filterPanel.addCheckbox(filterCheckbox);
    }
    return filterPanel.waitToRender();
  };
  ApproveState = (function() {

    ApproveState.allStates = [];

    ApproveState.initialNextStateIds = null;

    ApproveState.applyCurrentState = function(task) {
      var nextStateIds, state, _i, _len, _ref;
      nextStateIds = null;
      _ref = this.allStates;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        if (state.isUsedBy(task)) nextStateIds = state.nextStateIds;
      }
      if (nextStateIds == null) nextStateIds = this.initialNextStateIds;
      return this.renderNextStateButtons(nextStateIds, task);
    };

    ApproveState.renderNextStateButtons = function(nextStateIds, task) {
      var state, visible, _i, _len, _ref, _results;
      utils.log("all states before rendering: ", this.allStates);
      _ref = this.allStates;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        visible = nextStateIds.indexOf(state.id) >= 0 && (state.canBeSetOn(task));
        _results.push(state.button.setVisible(visible));
      }
      return _results;
    };

    function ApproveState(id, buttonCaption, filterName, tagText, nextStateIds, availableFor, newTaskState) {
      this.id = id;
      this.buttonCaption = buttonCaption;
      this.filterName = filterName;
      this.tagText = tagText;
      this.nextStateIds = nextStateIds;
      this.availableFor = availableFor;
      this.newTaskState = newTaskState;
      ApproveState.allStates.push(this);
      utils.log("new state created: ", this, "all states: ", ApproveState.allStates);
    }

    ApproveState.prototype.isUsedBy = function(task) {
      return (task.get("title")).indexOf(this.tagText) >= 0;
    };

    ApproveState.prototype.canBeSetOn = function(task) {
      return (this.availableFor === "responsible" && wrikeUtils.currentUserIsResponsibleForTask(task)) || (this.availableFor === "author" && wrikeUtils.currentUserIsAuthor(task));
    };

    ApproveState.prototype.applyTo = function(taskView) {
      var cleanedTitle, state, task, _i, _len, _ref;
      task = taskView["record"];
      cleanedTitle = task.get("title");
      _ref = ApproveState.allStates;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        cleanedTitle = cleanedTitle.replace(state.tagText, '');
      }
      task.set("title", this.tagText + cleanedTitle);
      if (this.newTaskState != null) task.set("state", this.newTaskState);
      task.save(taskView.callback);
      return this.render(task);
    };

    ApproveState.prototype.render = function(task) {
      return ApproveState.renderNextStateButtons(this.nextStateIds, task);
    };

    return ApproveState;

  })();
  WrikeFilterCheckbox = (function() {

    function WrikeFilterCheckbox(caption, tagText) {
      var container, form, label,
        _this = this;
      this.caption = caption;
      this.tagText = tagText;
      this.contents = $("<div style=\"padding-left:10px;\"></div>");
      container = $("<div class=\"x-form-check-wrap\"></div>");
      form = $("<div></div>", {
        "class": "x-form-checkbox-inner"
      });
      this.checkbox = $("<input>", {
        type: "checkbox",
        autocomplete: "off",
        "class": "x-form-checkbox x-form-field",
        click: function() {
          form.toggleClass("x-form-check-checked");
          return _this.updateQuery();
        }
      });
      label = $("<label></label>", {
        "class": "x-form-cb-label",
        text: this.caption
      });
      form.append(this.checkbox);
      container.append(form, label);
      this.contents.append(container);
    }

    WrikeFilterCheckbox.prototype.updateQuery = function() {
      var query, text;
      query = Wrike.env.FILTERS.get('text');
      if (this.checked()) {
        query.push(this.tagText);
      } else {
        query = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = query.length; _i < _len; _i++) {
            text = query[_i];
            if (text !== this.tagText) _results.push(text);
          }
          return _results;
        }).call(this);
      }
      return BUS.fireEvent('list.filter.changed', {
        text: query
      });
    };

    WrikeFilterCheckbox.prototype.checked = function() {
      return this.checkbox.is(":checked");
    };

    return WrikeFilterCheckbox;

  })();
  WrikeFilterPanel = (function() {

    WrikeFilterPanel.prototype.template = null;

    WrikeFilterPanel.prototype.checkboxContainer = null;

    WrikeFilterPanel.prototype._parentClass = 'w2-folder-listview-filters-filterspane-body';

    WrikeFilterPanel.prototype._getParent = function() {
      return $('.' + this._parentClass);
    };

    function WrikeFilterPanel(title) {
      this.contents = $("<div class=\"w2-folder-listview-filters-filterpane\">\n	<div class=\"w2-folder-listview-filters-filterpane-title x-unselectable\">" + title + "</div>\n	<div  class=\"x-form-check-group x-column-layout-ct x-form-field w2-folder-listview-filters-filterpane-chgroup\">\n		<div class=\"x-column-inner\" id=\"ext-gen1145\" style=\"width: 170px;\">\n			<div  class=\" x-column\" style=\"width: 170px;\">\n				<div class=\"x-form-item  x-hide-label\" tabindex=\"-1\"></div>\n				<div class=\"x-form-clear-left\"></div>\n			</div>\n		</div>\n	</div>\n</div>");
      this.checkboxContainer = this.contents.find(".x-form-item");
    }

    WrikeFilterPanel.prototype.waitToRender = function() {
      var that;
      that = this;
      utils.aspect.after(Ext.Panel, "afterRender", function() {
        if (this.bodyCssClass === that._parentClass) return that._render();
      });
      return this._render();
    };

    WrikeFilterPanel.prototype._render = function() {
      return this._getParent().append(this.contents);
    };

    WrikeFilterPanel.prototype.addCheckbox = function(checkbox) {
      return this.checkboxContainer.append(checkbox.contents);
    };

    return WrikeFilterPanel;

  })();
  wrikeUtils = {
    getCurrentUserId: function() {
      return w2.user.getUid();
    },
    currentUserIsResponsibleForTask: function(task) {
      return task.data["responsibleList"].indexOf(this.getCurrentUserId()) >= 0;
    },
    currentUserIsAuthor: function(task) {
      return (task.get('author')) === this.getCurrentUserId();
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
      if (currentTaskView != null) return cb(currentTaskView);
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
