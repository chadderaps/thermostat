// Userlist data array for filling in info box
// DOM Ready =============================================================
$(document).ready(function() {

  // Get the temperature and fill the fields
  getThermometer();

  setInterval(getThermometer, 2000);

});

// Functions =============================================================

function setColor(element, color) {
  console.log(element.style.backgroundColor);
  element.style.backgroundColor = color;
};

function getThermometer() {
  $.getJSON('/thermometer', function (thermometer) {
    console.log(thermometer);
    thermo = JSON.parse(thermometer)
    var tempLabel = $('#lblCurTemp')
    tempLabel.html(thermo.curTemp)
  });
};

// Fill table with data
function populateTable() {

    // Empty content string

    // jQuery AJAX call for JSON
    $.getJSON( '/temperature', function( thermometer ) {


        console.log(thermometer);

        // For each item in our JSON, add a table row and cells to the content string

        // Inject the whole content string into our existing HTML table
        $('#userList table tbody').html(tableContent);
    });
};

function doSomething(event) {
  console.log('stuff and that');
};

function showUserInfo(event) {
  console.log("Got Here");

  event.preventDefault();

  var thisUserName = $(this).attr('rel');

  var arrayPosition = userListData.map(function(arrayItem) { return arrayItem.username;}).indexOf(thisUserName);

  var thisUserObject = userListData[arrayPosition];

  console.log(thisUserObject);

  //Populate Info Box
  $('#userInfoName').text(thisUserObject.fullname);
  $('#userInfoAge').text(thisUserObject.age);
  $('#userInfoGender').text(thisUserObject.gender);
  $('#userInfoLocation').text(thisUserObject.location);

  setColor($('#userList table th')[0], 'blue');
};
