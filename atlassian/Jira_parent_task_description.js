function addon() {
  var parentDescription = function () {
    // Getting parent issue key if exists.
    var parentIssueKey = jQuery('#parent_issue_summary').data('issue-key');
    if (typeof parentIssueKey == 'undefined') return;

    // Getting parent issue details through REST API.
    // See https://docs.atlassian.com/jira/REST/latest/ for details.
    var getIssueDetails = function (key, parameters, callback) {
      jQuery.get('/rest/api/latest/issue/' + key + '?' + parameters, callback);
    };

    getIssueDetails(parentIssueKey, 'expand=renderedFields', function (data) {
      var parentDescription = data.renderedFields.description;
      if (parentDescription == '') return;

      // Cloning description block.
      var descriptionBlock = jQuery('#descriptionmodule');
      var block = descriptionBlock.clone().insertBefore(descriptionBlock);
      block.attr('id', 'parentdescriptionmodule');
      var title = block.find('.mod-header h2').text('Parent Description');

      // Setting parent description body.
      block.find('.mod-content .user-content-block').html(parentDescription);

      // Disabling inline edit for parent description block.
      block.find('.editable-field').removeClass('editable-field');
      block.find('.aui-iconfont-edit').hide();
    });
  };

  return {
    start: function (taistApi, entryPoint) {
      // Atlassian builds true-ajax applications, so classic tai.st
      // mech of calling script on page load wont' work.
      // We have to wait for window.location updates and manually
      // handle supported entry points.
      var loc = '';
      taistApi.wait.repeat(function () {
        return loc != window.location.pathname
      }, function () {
        // Saving new path to global loc variable.
        loc = window.location.pathname;

        // Processing entry points:
        //  1. Issue view page:
        if (/\/browse\/[a-zA-Z]+\-[0-9]+/.test(loc)) {
          taistApi.wait.once(function () {
            return jQuery('#summary-val').get(0)
          }, function () {
            parentDescription();
          });
        }
      });
    }
  };
}
