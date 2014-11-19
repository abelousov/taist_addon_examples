function addon() {
  function drawParentDescription () {
    var parentLinkEl = jQuery('#parent_issue_summary');
    if(parentLinkEl.length == 0)
      return;

    var parentIssueKey = parentLinkEl.data('issue-key');

    getIssueDetails(parentIssueKey, 'expand=renderedFields', function (data) {
      var parentDescription = data.renderedFields.description;
      if (parentDescription == '') {
        parentDescription = '[No description]';
      }

      // Cloning description block.
      var descriptionEl = jQuery('#descriptionmodule');
      var parentDescriptionEl = descriptionEl.clone().insertBefore(descriptionEl);
      parentDescriptionEl.attr('id', 'parentdescriptionmodule');
      parentDescriptionEl.find('.mod-header h2').text('Parent Description');

      // Setting parent description contents that is stored as html
      parentDescriptionEl.find('.mod-content .user-content-block').html(parentDescription);

      // Disabling inline edit for parent description block.
      parentDescriptionEl.find('.editable-field').removeClass('editable-field');
      parentDescriptionEl.find('.aui-iconfont-edit').hide();
    });
  }

  // Getting parent issue details through REST API.
  // See https://docs.atlassian.com/jira/REST/latest/ for details.
  function getIssueDetails (key, parameters, callback) {
    jQuery.get('/rest/api/latest/issue/' + key + '?' + parameters, callback);
  }

  return {
    start: function (taistApi) {
      // waiting for a field that appears only on issue page
      taistApi.wait.elementRender('#summary-val', drawParentDescription);
    }
  };
}
