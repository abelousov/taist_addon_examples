
(function() {
  var WrikeCheckbox, WrikeFilterCheckbox, WrikeFilterPanel, drawInProgressCheckbox, inprogressTagText, renderFilterPanel, start, utils, wrikeUtils;
  utils = null;
  inprogressTagText = "[In progress] ";
  start = function(utilities) {
    utils = utilities;
    wrikeUtils.onTaskViewRender(drawInProgressCheckbox);
    return renderFilterPanel();
  };
  drawInProgressCheckbox = function(task, taskView) {
    if (!(taskView.inProgressCheckbox != null)) {
      taskView.inProgressCheckbox = new WrikeCheckbox("In progress", function(checked) {
        var currentTask, currentTitle;
        currentTask = taskView["record"];
        currentTitle = currentTask.get('title');
        currentTask.set('title', (checked ? inprogressTagText + currentTitle : currentTitle.replace(inprogressTagText, '')));
        return currentTask.save(taskView.callback);
      });
    }
    taskView.inProgressCheckbox.setEnabled(wrikeUtils.currentUserIsResponsibleForTask(task));
    taskView.inProgressCheckbox.setChecked((task.get('title')).indexOf(inprogressTagText) >= 0);
    return $('td.info-importance').after(taskView.inProgressCheckbox.contents);
  };
  renderFilterPanel = function() {
    var filterPanel;
    filterPanel = new WrikeFilterPanel('In progress');
    filterPanel.addCheckbox(new WrikeFilterCheckbox("In progress", inprogressTagText));
    return filterPanel.waitToRender();
  };
  WrikeCheckbox = (function() {

    WrikeCheckbox.prototype.checkbox = null;

    WrikeCheckbox.prototype.contents = null;

    function WrikeCheckbox(text, onCheckedChange) {
      var _this = this;
      this.contents = $("<div style=\"padding-left:10px;\"><div  class=\"x-form-check-wrap\"  ><div class=\"x-form-checkbox-inner\"><input type=\"checkbox\" autocomplete=\"off\" class=\" x-form-checkbox x-form-field\"></div><label for=\"ext-inprogress\" class=\"x-form-cb-label\">" + text + "</label></div></div>");
      this.checkbox = this.contents.find('input');
      this.form = this.contents.find('.x-form-checkbox-inner');
      this.checkbox.click(function() {
        return onCheckedChange(_this.isChecked());
      });
    }

    WrikeCheckbox.prototype.isChecked = function() {
      return this.checkbox.is(":checked");
    };

    WrikeCheckbox.prototype.setEnabled = function(value) {
      if (value) {
        return this.checkbox.removeAttr('disabled');
      } else {
        return this.checkbox.attr('disabled', 'disabled');
      }
    };

    WrikeCheckbox.prototype.setChecked = function(value) {
      if (value) {
        this.checkbox.attr('checked', 'checked');
      } else {
        this.checkbox.removeAttr('checked');
      }
      return this.form.toggleClass('x-form-check-checked', value);
    };

    return WrikeCheckbox;

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
