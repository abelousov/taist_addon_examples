
(function() {
  var ApproveState, StateMachine, WrikeFilterCheckbox, WrikeFilterPanel, addStateMachine, buttonsContainer, createButton, render, renderFilterPanel, start, utils, wrikeUtils;
  utils = null;
  buttonsContainer = null;
  start = function(utilities) {
    utils = utilities;
    return wrikeUtils.onTaskViewRender(render);
  };
  render = function(task) {
    var stateMachine;
    if (task != null) {
      stateMachine = addStateMachine();
      stateMachine.task = task;
      return stateMachine.applyCurrentState();
    }
  };
  addStateMachine = function() {
    var buttonsContainerClass, prevElement, state, stateMachine, _fn, _i, _len, _ref;
    stateMachine = new StateMachine();
    buttonsContainerClass = "taist-stateButtonsContainer";
    buttonsContainer = $('.' + buttonsContainerClass);
    if (buttonsContainer.length === 0) {
      utils.log('buttons container doesnot exist, creating new one');
      buttonsContainer = $('<div class="#{buttonsContainerClass}"></div>');
      prevElement = $('.wspace-task-importance-button');
      prevElement.after(buttonsContainer);
      utils.log('inserted buttons container: ', prevElement, buttonsContainer, buttonsContainer.parent());
    } else {
      utils.log('emptying buttons container: ', buttonsContainer);
      buttonsContainer.empty();
      utils.log('emptying result: ', buttonsContainer);
    }
    _ref = stateMachine.allStates;
    _fn = function(state) {
      var button;
      button = createButton(state, stateMachine);
      buttonsContainer.append(button);
      return state.button = button;
    };
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      state = _ref[_i];
      _fn(state);
    }
    return stateMachine;
  };
  createButton = function(state, stateMachine) {
    var button;
    button = $("<a class=\"wrike-button-base x-btn-noicon\" style=\"width: auto; float: left; margin-left: 15px;\">" + state.buttonCaption + "</a>");
    button.click(function() {
      stateMachine.changeState(state);
      return false;
    });
    return button;
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
  StateMachine = (function() {

    StateMachine.prototype.allStates = [];

    StateMachine.prototype._initialNextStateIds = "toApprove";

    StateMachine.prototype.task = null;

    function StateMachine() {
      this.allStates.push(new ApproveState("toApprove", "To approve", "To approve", "[ToApprove] ", ["declined", "approved"], "responsible", null));
      this.allStates.push(new ApproveState("declined", "Decline", "Declined", "[Declined] ", ["toApprove"], "author", null));
      this.allStates.push(new ApproveState("approved", "Approve", "Approved", "[Approved] ", [], "responsible", "1"));
    }

    StateMachine.prototype.applyCurrentState = function() {
      var currentState, state, _i, _len, _ref;
      currentState = null;
      _ref = this.allStates;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        if (state.isUsedBy(this.task)) currentState = state;
      }
      return this._applyState(currentState, false);
    };

    StateMachine.prototype.changeState = function(state) {
      return this._applyState(state, true);
    };

    StateMachine.prototype._applyState = function(newState, needUpdate) {
      var nextStateIds, state, visible, _i, _len, _ref, _ref2, _results;
      if (needUpdate) this._updateTaskWithState(newState);
      nextStateIds = (_ref = newState != null ? newState.nextStateIds : void 0) != null ? _ref : this._initialNextStateIds;
      _ref2 = this.allStates;
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        state = _ref2[_i];
        visible = nextStateIds.indexOf(state.id) >= 0 && (state.canBeSetOn(this.task));
        _results.push(state.button.toggle(visible));
      }
      return _results;
    };

    StateMachine.prototype._updateTaskWithState = function(currentState) {
      var state, _i, _len, _ref;
      _ref = this.allStates;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        state = _ref[_i];
        state.removeFromTask(this.task);
      }
      currentState.addToTask(this.task);
      return this.task.save();
    };

    return StateMachine;

  })();
  ApproveState = (function() {

    ApproveState.prototype.nextStateIds = null;

    ApproveState.prototype.availableFor = null;

    ApproveState.prototype.button = null;

    function ApproveState(id, buttonCaption, filterName, tagText, nextStateIds, availableFor, newTaskState) {
      this.id = id;
      this.buttonCaption = buttonCaption;
      this.filterName = filterName;
      this.tagText = tagText;
      this.nextStateIds = nextStateIds;
      this.availableFor = availableFor;
      this.newTaskState = newTaskState;
    }

    ApproveState.prototype.isUsedBy = function(task) {
      return (task.get("title")).indexOf(this.tagText) >= 0;
    };

    ApproveState.prototype.canBeSetOn = function(task) {
      if (this.availableFor === "responsible") {
        return wrikeUtils.currentUserIsResponsibleForTask(task);
      } else if (this.availableFor === "author") {
        return wrikeUtils.currentUserIsAuthor(task);
      } else {
        return null;
      }
    };

    ApproveState.prototype.addToTask = function(task) {
      task.set('title', this.tagText + (task.get('title')));
      if (this.newTaskState != null) return task.set("state", this.newTaskState);
    };

    ApproveState.prototype.removeFromTask = function(task) {
      return task.set('title', (task.get('title')).replace(this.tagText, ''));
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
    getCurrentTaskView: function() {
      return window.Ext.ComponentMgr.get($('.w3-task-view').attr('id'));
    },
    getCurrentTask: function() {
      var _ref;
      return (_ref = this.getCurrentTaskView()) != null ? _ref["record"] : void 0;
    },
    onTaskViewRender: function(callback) {
      var currentTask, currentTaskView, currentViewListeners, enhancedListener, listenerName, listenersInPrototype, _ref;
      listenerName = "beforesetrecord";
      listenersInPrototype = w2.task.View.prototype.xlisteners;
      utils.aspect.after(listenersInPrototype, listenerName, function(view, task) {
        if (task != null) {
          return task.load(function(loadedTask) {
            utils.log('set task: ', loadedTask.data.title);
            return callback(loadedTask, view);
          });
        } else {
          utils.log('unset task');
          return callback(null, view);
        }
      });
      _ref = [this.getCurrentTask(), this.getCurrentTaskView()], currentTask = _ref[0], currentTaskView = _ref[1];
      if ((currentTask != null) && (currentTaskView != null)) {
        enhancedListener = listenersInPrototype[listenerName];
        currentViewListeners = currentTaskView.events[listenerName].listeners[0];
        currentViewListeners.fn = currentViewListeners.fireFn = enhancedListener;
        return callback(currentTask, currentTaskView);
      }
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
