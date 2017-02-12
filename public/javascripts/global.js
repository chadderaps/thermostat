// Userlist data array for filling in info box
// DOM Ready =============================================================
$(document).ready(function() {

  $.ajaxSetup({timeout: 5000})
  // Get the temperature and fill the fields
  //getThermostat();

  //setInterval(getThermostat, 2000);
  alert(document.location.origin);
  var socket = io.connect(document.location.origin);

  socket.emit('temperature', 'chad deraps');
  socket.on('reconnect', function() {
    console.log('Reconnecting to the server');
    socket.emit('temperature', 'chad deraps');
  });

  socket.on('reconnecting', function () {
    console.log('Attempting to reconnect to the server');
  });

  socket.on('temperature', function(data) {
    var tempLabel = $('#lblCurTemp');
    tempLabel.html(data.temperature);
  });

});

function changeTemp(dir) {
  var data = {'direction':dir}
  //$.post('http://localhost:3001/thermostat/changeTemp', {direction: dir});
  $.ajax({
    type: 'POST',
    url: '/thermostat/changeTemp',
    contentType: 'application/json',
    dataType: 'json',
    data: JSON.stringify({direction: dir}),
    success: function () {
      console.log('Done Posting')
    }
  });
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

    getThermostat();
}

function getThermostat() {
  $.ajax({
    url: '/thermostat/currentTemp',
    dataType: 'json',
    success: loadThermostat,
    error: loadThermostat,
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
