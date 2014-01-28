// Generated by CoffeeScript 1.6.3
(function() {
  var WrikeTaskApprover, WrikeTaskFilters, approver, filters, start, states, taistWrike, utils, wrikeConstants;
  utils = null;
  approver = null;
  states = {
    'initial': {
      triggers: {
        'Send for approval': 'onApproval'
      },
      owner: true
    },
    'onApproval': {
      triggers: {
        'Approve': 'accepted',
        'Decline': 'declined'
      },
      titleTag: 'To Approve',
      author: true
    },
    'accepted': {
      titleTag: 'Approved',
      owner: true
    },
    'declined': {
      triggers: {
        'Send for approval': 'onApproval'
      },
      titleTag: 'Declined',
      owner: true
    }
  };
  wrikeConstants = {
    common: {
      classHidden: 'wrike-taist-hidden',
      hiddenClassCss: '<style> .wrike-taist-hidden {display: none;} </style>'
    },
    filters: {
      flagTemplate: '<a class="wrike-button-checkbox x-btn-noicon" href="#"></a>',
      taistFiltersContainerId: 'wrike-taist-approval-filters',
      flagsOuterContainerSelector: '.type-selector',
      flagsInnerContainerSelector: '.x-column',
      flagCheckedClass: 'x-btn-pressed',
      streamTaskSelector: '.stream-task-entry',
      streamViewButtonSelector: '.wspace_header_buttonStreamView'
    },
    task: {
      containerSelector: '.wspace-task-widgets-title-view',
      toolbarSelector: '.wspace-task-settings-bar',
      taistToolbarId: 'wrike-taist-toolbar',
      buttonTemplate: '<a class="wspace-task-settings-button"></a>',
      buttonHighlightClass: 'x-btn-over'
    }
  };
  WrikeTaskFilters = (function() {
    function WrikeTaskFilters() {}

    WrikeTaskFilters.prototype.filter = 'All';

    WrikeTaskFilters.prototype.cfg = wrikeConstants.filters;

    WrikeTaskFilters.prototype.renderFlags = function() {
      var flag, flags, flagsContainer, originalFlags, self, state, _, _results;
      if ($('#' + this.cfg.taistFiltersContainerId).length) {
        return;
      }
      originalFlags = $(this.cfg.flagsOuterContainerSelector);
      flags = originalFlags.clone();
      flags.attr('id', this.cfg.taistFiltersContainerId);
      flagsContainer = flags.find(this.cfg.flagsInnerContainerSelector);
      flagsContainer.empty();
      originalFlags.after(flags);
      self = this;
      _results = [];
      for (_ in states) {
        state = states[_];
        flag = $(self.cfg.flagTemplate);
        flag.text(state.titleTag || 'All');
        flagsContainer.append(flag);
        if (this.filter === flag.text()) {
          flag.addClass(self.cfg.flagCheckedClass);
        }
        _results.push(flag.on('click', function() {
          flagsContainer.find('a').removeClass(self.cfg.flagCheckedClass);
          $(this).addClass(self.cfg.flagCheckedClass);
          self.filter = $(this).text();
          self.filterTasks();
          return false;
        }));
      }
      return _results;
    };

    WrikeTaskFilters.prototype.filterTasks = function() {
      var hidden,
        _this = this;
      hidden = wrikeConstants.common.classHidden;
      return $(this.cfg.streamTaskSelector).each(function(i, element) {
        var elm, taskTitle;
        elm = $(element);
        if (_this.filter === 'All') {
          return elm.removeClass(hidden);
        } else {
          taskTitle = elm.find('span').text();
          if (taskTitle.match('\\[' + _this.filter + '\\]')) {
            return elm.removeClass(hidden);
          } else {
            return elm.addClass(hidden);
          }
        }
      });
    };

    return WrikeTaskFilters;

  })();
  WrikeTaskApprover = (function() {
    function WrikeTaskApprover() {}

    WrikeTaskApprover.prototype.cfg = wrikeConstants.task;

    WrikeTaskApprover.prototype.setTask = function(task) {
      var originalToolbar, roles;
      if (this.task === task) {
        return;
      }
      this.task = task;
      this.title = $(this.cfg.containerSelector).find('textarea');
      this.state = this.stateFromTitle();
      if ($(this.cfg.taistToolbarId).length) {
        return;
      }
      originalToolbar = $(this.cfg.toolbarSelector);
      this.toolbar = originalToolbar.clone();
      this.toolbar.attr('id', this.cfg.taistToolbarId);
      this.toolbar.empty();
      originalToolbar.after(this.toolbar);
      roles = taistWrike.myTaskRoles(task);
      if (roles.owner && states[this.state].owner || roles.author && states[this.state].author) {
        return this.renderControls();
      }
    };

    WrikeTaskApprover.prototype.stateFromTitle = function() {
      var m, state, stateName;
      m = this.title.val().match(/^\[(.+)\].*/);
      if (!(m != null ? m[1] : void 0)) {
        return 'initial';
      }
      for (stateName in states) {
        state = states[stateName];
        if (state.titleTag === m[1]) {
          return stateName;
        }
      }
    };

    WrikeTaskApprover.prototype.renderControls = function() {
      var buttonTitle, cfg, mOut, mOver, nextState, _ref, _results,
        _this = this;
      cfg = this.cfg;
      mOver = function() {
        return $(this).addClass(cfg.buttonHighlightClass);
      };
      mOut = function() {
        return $(this).removeClass(cfg.buttonHighlightClass);
      };
      _ref = states[this.state].triggers;
      _results = [];
      for (buttonTitle in _ref) {
        nextState = _ref[buttonTitle];
        _results.push((function(buttonTitle, nextState) {
          var button;
          button = $(cfg.buttonTemplate);
          button.text(buttonTitle);
          button.hover(mOver, mOut);
          button.on('click', function() {
            _this.toolbar.empty();
            _this.applyState(nextState);
            _this.renderControls();
            return false;
          });
          return _this.toolbar.append(button);
        })(buttonTitle, nextState));
      }
      return _results;
    };

    WrikeTaskApprover.prototype.applyState = function(newState) {
      var newPrefix;
      newPrefix = '[' + states[newState].titleTag + '] ';
      if (this.state === 'initial') {
        this.title.val(this.title.val());
      } else {
        this.title.val(this.title.val().replace(/^\[.+\]\s/, newPrefix));
      }
      this.title.focus();
      $.event.trigger({
        type: 'keypress',
        which: 13
      });
      this.title.blur();
      return this.state = newState;
    };

    return WrikeTaskApprover;

  })();
  approver = new WrikeTaskApprover();
  filters = new WrikeTaskFilters();
  start = function(utilities) {
    var style;
    utils = utilities;
    style = $(wrikeConstants.common.hiddenClassCss);
    $('html > head').append(style);
    taistWrike.onTaskViewRender(function(task) {
      if (!task) {
        return;
      }
      return approver.setTask(task);
    });
    $(wrikeConstants.filters.streamViewButtonSelector).on('click', function() {
      filters.renderFlags();
      filters.filterTasks();
      return false;
    });
    if (window.location.hash.match(/stream/)) {
      filters.renderFlags();
      return filters.filterTasks();
    }
  };
  taistWrike = {
    me: function() {
      return $wrike.user.getUid();
    },
    myTaskRoles: function(task) {
      return {
        owner: task.data['responsibleList'].indexOf(this.me()) >= 0,
        author: (task.get('author')) === this.me()
      };
    },
    onTaskViewRender: function(callback) {
      var currentTask, currentTaskView, currentViewListeners, enhancedListener, listenerName, listenersInPrototype;
      listenerName = 'load';
      listenersInPrototype = $wspace.task.View.prototype.xlisteners;
      utils.aspect.after(listenersInPrototype, listenerName, function(view, task) {
        if (task != null) {
          return task.load(function(loadedTask) {
            return callback(loadedTask, view);
          });
        } else {
          return callback(null, view);
        }
      });
      currentTaskView = window.Ext.ComponentMgr.get($('.wspace-task-view').attr('id'));
      currentTask = currentTaskView != null ? currentTaskView['record'] : void 0;
      if ((currentTask != null) && (currentTaskView != null)) {
        enhancedListener = listenersInPrototype[listenerName];
        currentViewListeners = currentTaskView.events[listenerName].listeners[0];
        currentViewListeners.fn = currentViewListeners.fireFn = enhancedListener;
        return callback(currentTask, currentTaskView);
      }
    },
    onTaskChange: function(callback) {
      return utils.aspect.after(Wrike.Task, 'getChanges', (function() {
        return callback(this);
      }));
    }
  };
  return {
    start: start
  };
});
