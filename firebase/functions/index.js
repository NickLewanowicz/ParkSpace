
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.getNearest = functions.database.ref('/users/{pushId}/location').onWrite(event =>{
   //const original = event.data.val(); //will give you the location of the user
    return admin.database().ref('users/').once('value', (snapshot) => {
        var snap = snapshot.val(); //this gives you the list of all the users and their childrens        
        console.log(snap);
    });
}
);




