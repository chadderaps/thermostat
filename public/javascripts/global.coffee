console.log 'Stuff and that'

module.exports =
  userListData = []

  populateTable = () =>
    tableContent = ''
    console.log 'lets get some user data'

    $.getJSON '/users/userlist', (data) =>
      $.each data, () =>
        tableContent += '<tr>'
        tableContent += '<td><a href="#" class="linkshowuser" rel="' + @username + '">' + @username + '</a></td>'
        tableContent += '<td>' + @email + '</td>'
        tableContent += '<td><a href="#" class="linkdeleteuser" rel="' + @_id + '">delete</a></td>'
        tableContent += '</tr>'

      $('#userList table tbody').html(tableContent)
