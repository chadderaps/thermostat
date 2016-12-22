// Userlist data array for filling in info box
// DOM Ready =============================================================
$(document).ready(function() {

  // Get the temperature and fill the fields
  getThermometer();

  //setInterval(getThermometer, 2000);

});

function changeTemp(dir) {
  var data = {'direction':dir}
  $.post('/thermometer/changeTemp', {direction: dir});
  getThermometer();
};

// Functions =============================================================

function getThermometer() {
  $.getJSON('/thermometer', function (thermometer) {
    console.log(thermometer);
    thermo = JSON.parse(thermometer);
    var tempLabel = $('#lblCurTemp');
    tempLabel.html(thermo.curTemp);
    $('#lblSetTemp').html(thermo.minTemp);

    setThermostatState(thermo.status)
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
