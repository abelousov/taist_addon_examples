
(function() {
  var addColorPicker, colorStateNameInput, docMap, drawColorPicker, drawColorPickers, drawColorSettings, drawRow, getColorFromStateInput, getCompanyName, getCurrentDocTypeOnStatesSettingsPage, getDocsTable, getStateColorFromStateSettingsPage, getStateColorOnDocsPage, getStateColumnIndex, getStateFromInput, getStateInputs, getStoredStateColor, getUserSettings, onCurrentDocTypeChanged, redrawRows, saveButtonSelector, saveCurrentStatesColors, setUserSettings, start, userSettings, utils, waitDrawButton, watchForRowsToRedraw;
  utils = null;
  userSettings = [];
  start = function(utilities, entryPoint) {
    utils = utilities;
    return utils.wait.once((function() {
      return getCompanyName().length > 0;
    }), function() {
      return getUserSettings(function() {
        if (entryPoint === 'user') {
          return watchForRowsToRedraw();
        } else {
          return drawColorSettings();
        }
      });
    });
  };
  getCompanyName = function() {
    return $('.companyName>span').text();
  };
  getUserSettings = function(callback) {
    return utils.userData.get('', (function(error, value) {
      userSettings = value;
      return callback();
    }), getCompanyName());
  };
  getStoredStateColor = function(docType, state) {
    var contKey, setting, _i, _len;
    contKey = JSON.stringify({
      currentDocType: docType,
      status: state
    });
    for (_i = 0, _len = userSettings.length; _i < _len; _i++) {
      setting = userSettings[_i];
      if (setting.key === contKey) return setting;
    }
    return null;
  };
  getStateColorOnDocsPage = function(state) {
    var cutHash, docHash, hash, _i, _len, _ref;
    hash = location.hash;
    cutHash = hash;
    if (hash.indexOf('?') >= 0) cutHash = hash.substr(0, hash.indexOf('?'));
    for (_i = 0, _len = docMap.length; _i < _len; _i++) {
      docHash = docMap[_i];
      if (docHash.hash === cutHash) {
        return (_ref = getStoredStateColor(docHash.key, state)) != null ? _ref.value : void 0;
      }
    }
  };
  getStateColorFromStateSettingsPage = function(state) {
    return getStoredStateColor(getCurrentDocTypeOnStatesSettingsPage(), state);
  };
  setUserSettings = function(setting, cb) {
    return utils.userData.set(setting.key, setting.value, cb, getCompanyName());
  };
  watchForRowsToRedraw = function() {
    return utils.wait.elementRender((function() {
      return getDocsTable().find("tbody tr");
    }), function(rows) {
      return redrawRows(rows);
    });
  };
  redrawRows = function(rows) {
    var row, stateColumnIndex, _i, _len, _results;
    stateColumnIndex = getStateColumnIndex(getDocsTable());
    if (stateColumnIndex) {
      _results = [];
      for (_i = 0, _len = rows.length; _i < _len; _i++) {
        row = rows[_i];
        _results.push(drawRow($(row), stateColumnIndex));
      }
      return _results;
    }
  };
  drawRow = function(jqRow, stateColumnIndex) {
    var color, state;
    state = $(jqRow.find('td')[stateColumnIndex]).find('[title]').text();
    color = getStateColorOnDocsPage(state);
    if (color != null) {
      return jqRow.children().attr('style', 'background:' + color + '!important');
    }
  };
  getDocsTable = function() {
    return $('table.b-document-table');
  };
  getStateColumnIndex = function(docsTable) {
    var column, i, _len, _ref;
    _ref = docsTable.find('thead').find('tr[class!="floating-header"]').find('th');
    for (i = 0, _len = _ref.length; i < _len; i++) {
      column = _ref[i];
      if ($(column).find('[title="Статус"]').length > 0) return i;
    }
    return null;
  };
  drawColorSettings = function() {
    waitDrawButton(function(saveButton) {
      return saveButton.click(function() {
        saveCurrentStatesColors();
        return drawColorPickers();
      });
    });
    return onCurrentDocTypeChanged(drawColorPickers);
  };
  onCurrentDocTypeChanged = function(callback) {
    var currentDocType, docTypeOnStatesPageChanged;
    currentDocType = '<No current doc type>';
    docTypeOnStatesPageChanged = function() {
      var newDocType;
      newDocType = getCurrentDocTypeOnStatesSettingsPage();
      return (newDocType != null) && newDocType !== currentDocType;
    };
    return utils.wait.repeat(docTypeOnStatesPageChanged, function() {
      currentDocType = getCurrentDocTypeOnStatesSettingsPage();
      return callback();
    });
  };
  waitDrawButton = function(callback) {
    return utils.wait.elementRender(saveButtonSelector, callback);
  };
  saveButtonSelector = '.b-popup-button-green';
  saveCurrentStatesColors = function() {
    var currentColor, inputObj, jqInput, key, state, value, _i, _len, _ref, _results;
    _ref = getStateInputs();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      inputObj = _ref[_i];
      jqInput = $(inputObj);
      state = getStateFromInput(jqInput);
      if (state.length > 0) {
        key = JSON.stringify({
          currentDocType: getCurrentDocTypeOnStatesSettingsPage(),
          status: state
        });
        value = jqInput.getHexBackgroundColor();
        currentColor = getStateColorFromStateSettingsPage(state);
        if (currentColor != null) {
          currentColor.value = value;
        } else {
          userSettings.push({
            key: key,
            value: value
          });
        }
        _results.push(setUserSettings({
          key: key,
          value: value
        }, function() {}));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };
  getCurrentDocTypeOnStatesSettingsPage = function() {
    if (location.hash === '#states') {
      return $('.gwt-TreeItem-selected').text();
    } else {
      return null;
    }
  };
  getStateInputs = function() {
    return $('input.gwt-TextBox[size="40"]');
  };
  getStateFromInput = function(input) {
    return input.val();
  };
  drawColorPickers = function() {
    var stateNameInput, _i, _len, _ref, _results;
    _ref = getStateInputs();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      stateNameInput = _ref[_i];
      _results.push(drawColorPicker($(stateNameInput)));
    }
    return _results;
  };
  drawColorPicker = function(jqStateInput) {
    colorStateNameInput(jqStateInput);
    return addColorPicker(jqStateInput);
  };
  getColorFromStateInput = function(input) {
    return getStateColorFromStateSettingsPage(getStateFromInput(input));
  };
  colorStateNameInput = function(input) {
    var _ref, _ref2;
    return input.css({
      background: (_ref = (_ref2 = getColorFromStateInput(input)) != null ? _ref2.value : void 0) != null ? _ref : 'white'
    });
  };
  addColorPicker = function(input) {
    var picker;
    picker = $('<td></td>');
    input.parent().after(picker);
    return picker.colourPicker({
      colorPickCallback: function(hexColor) {
        return input.css({
          background: '#' + hexColor
        });
      }
    });
  };
  $.fn.getHexBackgroundColor = function() {
    var hex, hex_rgb, rgb;
    rgb = $(this).css('background-color');
    if (!rgb) return '#FFFFFF';
    hex_rgb = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
    if (hex_rgb) {
      hex = function(x) {
        return ("0" + parseInt(x).toString(16)).slice(-2);
      };
      return "#" + hex(hex_rgb[1]) + hex(hex_rgb[2]) + hex(hex_rgb[3]);
    } else {
      return rgb;
    }
  };
  jQuery.fn.colourPicker = function(conf) {
    var colors, colourPicker, config, hexInvert;
    config = jQuery.extend({
      id: 'jquery-colour-picker',
      title: 'Pick a colour',
      speed: 500,
      openTxt: 'Open colour picker',
      inputId: 0,
      colorPickCallback: function(hex, inputId) {}
    }, conf);
    colors = ['99', 'CC', 'FF'];
    hexInvert = function(hex) {
      var b, g, r, _ref;
      r = hex.substr(0, 2);
      g = hex.substr(2, 2);
      b = hex.substr(4, 2);
      return (_ref = 0.212671 * r + 0.715160 * g + 0.072169 * b < 0.5) != null ? _ref : {
        'ffffff': '000000'
      };
    };
    colourPicker = jQuery('#' + config.id);
    if (!colourPicker.length) {
      colourPicker = jQuery('<div id="' + config.id + '"></div>').appendTo(document.body).hide();
      jQuery(document.body).click(function(event) {
        if (!(jQuery(event.target).is('#' + config.id) || jQuery(event.target).parents('#' + config.id).length)) {
          return colourPicker.hide(config.speed);
        }
      });
    }
    return this.each(function() {
      var bColor, gColor, hex, icon, iconDiv, loc, rColor, select, _i, _j, _k, _len, _len2, _len3;
      select = jQuery(this);
      iconDiv = jQuery('<img icondiv src="data:image/gif;base64,R0lGODlhFwATAPcAAM/R0WKXY9/j5bm8wWCUY+lmaquyt9LV1PPz81VwpVp1rX3lZXniZ67iZFh2qld1qlhyqeTmaX3jZMLGyuZpZ6/jZ+e2Z+iAZq2zueZlZV6UY8/P0c3Nz8vLz+qCaVmm3KngYVVzqea2aHbhX6extVZadWR8ZmB4YuuCbGGTYYvb3F98YmJ7ZVan26qut9fX17i7wMrLzbvAw7i8v7e8v6mssdnZ2crOz6itscfLznvhYonY3Om1aldbeGOXZlZad1ip3ufoaKistdTU1Nvb29DQ0OhracjMzcTFybm+wrW4vVSl3PHx8eizZ8rKzMnKzqats7e8wMDEx8HFxujobP/+/+q2a8bHybi7wtLR1tLS1KivtamttqqvtbG2uleo3cjJzc3Pzuq3Zqiws+traGKTZNXT1ofa3rDkZsvO1cfLzFZdd1V1plZac1yp4eayZld2rKivt1eq3F2p3eflaqzjYWOVZOO0ZrW6vsvLzednaGGXZsPDxbO2u+bnaFlaeauws6attaSvs7a+wLW9wMHCx6+3ulxceOPl5OaBaeLnaYnX2+Pj47/EyuiyaLO6wLa5wMnQ1mSVZsnKzGN9ZFx2qtrY2bq7wMTJzNfZ2Ku0uehoZ6uvunfhZaqvs+Pk5tHT0tPT01ek2rCzur7ExOlpaOlpamCSX+tpa6qusepqa47c3ova3pDc3LO4u+fpbOm0aMrMy63hZYvZ2b3Ax7/AxLG5vL7DxszKzeXnaujo6MbHy6zgYYvc3a/jZIza3rm8w8PDy66zucDDzHffYrS5v7a7v6yxtFNXdFem3ubmbHniYo3c4HrgYHrjY2GVZOi3a2CWZbzCwlRYdby/xldYdOTk5LS+v7/DxOmBaKqxuemDauuDaavhZf///YjY2crKyora267gY8TKytPS1+eEZ6ausefpaufqacXJyltddsfIyud/Zq20vIfY27DlY2F/Zefn52N8ZuWAZLC3va+0umJ8Y1xbeuXmZ+eCZunpba+2vP7//9bW1tjY2P///yH5BAAAAAAALAAAAAAXABMAAAj/AP/9Q2CNiD8bNvwpXLjQBhFGCAT+i+evn78XLxhqrHjxha5/TPqJHEmyZL8XJJlYOkDlnD4qZqBZsWDlALdt3FAMMYJKFZkhmUBleYUuSJBQFniIgaUFRbZyHrSUomDEVBZyRYrkouNH2QYeIpqIAHAhX6JEGwpQ2EQBwAYON/D5iaDoxps7TRzdYJdo3oUwGfQE5sChA64Yk2LkyPPkSI4Y4GI4eeIkRwc1OWKBOYLpSgU0vt7tWiBBwoJ1Pvb4CJDOBCV4JsZdCTalge06E3Q4k8Bggh1JBKJNWWFCHgskSPjckiWuQTdSyxg004HtWYoyBArZY7FihRQptWSA3OAFAgStEcRGdJJxSkN7GSfin5BGbQYNYFiiXJuB5dIAGDAMYgwMMwxAAww0EBLFDEpAwkorqzDjihtAADEHHgpUUgkcxdyjTg+HKPGIIV708osKs9jywRdfyOEFHGw84AA9bZSwRg997JPEKGeEs4MKGLTQQjIttPMABEcKU8IfP/xQTxICGLDIDu58w8kSonywxDEJhBACBNqUgEw102gjQBVpAMKFJ12Q4MKbLmwRxxgukLAFF12k4kIkVfDzzyfDaIKDEDXgEIggNQhhDg5Q1AAFBo0g4s0/AQEAOw==" />');
      icon = jQuery('<a href="#"></a>');
      select.append(icon);
      icon.append(iconDiv);
      loc = '';
      for (_i = 0, _len = colors.length; _i < _len; _i++) {
        rColor = colors[_i];
        for (_j = 0, _len2 = colors.length; _j < _len2; _j++) {
          gColor = colors[_j];
          for (_k = 0, _len3 = colors.length; _k < _len3; _k++) {
            bColor = colors[_k];
            hex = rColor + gColor + bColor;
            loc += '<li><a href="#"  rel="' + hex + '" style="background: #' + hex + '; colour: ' + hexInvert(hex) + ';"></a></li>';
          }
        }
      }
      return icon.click(function() {
        var heading, iconPos, _ref;
        iconPos = icon.offset();
        heading = (_ref = config.title) != null ? _ref : '<h2>' + config.title + {
          '</h2>': ''
        };
        colourPicker.html(heading + '<ul>' + loc + '</ul>').css({
          position: 'absolute',
          left: iconPos.left + 'px',
          top: iconPos.top + 'px'
        });
        colourPicker.show(config.speed);
        jQuery('a', colourPicker).click(function() {
          hex = jQuery(this).attr('rel');
          config.colorPickCallback(hex, config.inputId);
          colourPicker.hide(config.speed);
          return false;
        });
        return false;
      });
    });
  };
  docMap = [
    {
      key: "Заказ поставщику",
      hash: "#purchaseorder"
    }, {
      key: "Счет поставщика",
      hash: "#invoicein"
    }, {
      key: "Приёмка",
      hash: "#supply"
    }, {
      key: "Возврат поставщику",
      hash: "#purchasereturn"
    }, {
      key: "Счёт-фактура полученный",
      hash: "#facturein"
    }, {
      key: "Заказ покупателя",
      hash: "#customerorder"
    }, {
      key: "Счет покупателю",
      hash: "#invoiceout"
    }, {
      key: "Отгрузка",
      hash: "#demand"
    }, {
      key: "Возврат покупателя",
      hash: "#salesreturn"
    }, {
      key: "Счёт-фактура выданный",
      hash: "#factureout"
    }, {
      key: "Прайс-лист",
      hash: "#pricelist"
    }, {
      key: "Списание",
      hash: "#loss"
    }, {
      key: "Оприходование",
      hash: "#enter"
    }, {
      key: "Перемещение",
      hash: "#move"
    }, {
      key: "Инвентаризация",
      hash: "#inventory"
    }, {
      key: "Технологическая операция",
      hash: "#processing"
    }, {
      key: "Заказ на производство",
      hash: "#processingorder"
    }, {
      key: "Внутренний заказ",
      hash: "#internalorder"
    }, {
      key: "Входящий платеж",
      hash: "#paymentin"
    }, {
      key: "Приходный ордер",
      hash: "#cashin"
    }, {
      key: "Исходящий платеж",
      hash: "#paymentout"
    }, {
      key: "Расходный ордер",
      hash: "#cashout"
    }
  ];
  return {
    start: start
  };
});
