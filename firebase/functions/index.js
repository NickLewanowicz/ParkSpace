const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.getNearest = functions.database.ref('/users/{pushId}')
.onWrite(event => {

  console.log('getNearest', event);
  
  return event
});



