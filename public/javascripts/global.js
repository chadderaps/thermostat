// Userlist data array for filling in info box
// DOM Ready =============================================================
$(document).ready(function() {

  $.ajaxSetup({timeout: 5000})
  // Get the temperature and fill the fields
  getThermometer();

  //setInterval(getThermometer, 2000);

});

function changeTemp(dir) {
  var data = {'direction':dir}
  $.post('/thermometer/changeTemp', {direction: dir});
  //getThermometer();
};

// Functions =============================================================

function loadThermostat(therm) {
    console.log(therm);
    thermo = JSON.parse(therm);
    var tempLabel = $('#lblCurTemp');

    if (thermo.curTemp !== null) {
      tempLabel.html(thermo.curTemp);
      $('#lblSetTemp').html(Math.round(thermo.minTemp));

      setThermostatState(thermo.status);
    }

    getThermometer();
}

function getThermometer() {
  $.ajax({
    url: '/thermometer',
    dataType: 'json',
    success: loadThermostat,
    error: getThermometer
  });
};

function setThermostatState(status) {

  state =  ((status) ?  'On' : 'Off');
  alternateState = ((status) ? 'Off' : 'On')

  enableElem = $('#lblThermo' + state)
  disableElem = $('#lblThermo' + alternateState)

  enableElem.html(state)

  disableElem.html('')
}
