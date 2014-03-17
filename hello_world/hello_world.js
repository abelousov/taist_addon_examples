function init() {
  var taistApi;

  function doWork() {
    alert("Hello, world! This is my first addon!");
    taistApi.log("Hello, console!");
  }

  var addonEntry = {
    start: function(_taistApi, entryPoint) {
      taistApi = _taistApi;
      doWork();
    }
  };

  return addonEntry;
}
