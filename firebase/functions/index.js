
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.getNearest = functions.database.ref('/users/{pushId}/location').onWrite(event =>{
    //const config = functions.config();
    //const adminUsersString = config.['access-control-list']['admin-users'];
    //const original = event.data.val();
    //console.log('Uppercasing', event.params.pushId, original);
    //const uppercase = original.toUpperCase();
    console.log(event);
    //return event.data.ref.parent.child('uppercase').set(uppercase);
}
);




