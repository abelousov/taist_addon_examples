
(function() {
  return {
    start: function(utils) {
      utils.dev.logMethodCalls(window.Teamlab, "Teamlab");
      return utils.dev.logMethodCalls(window.ServiceManager, "ServiceManager");
    }
  };
});
