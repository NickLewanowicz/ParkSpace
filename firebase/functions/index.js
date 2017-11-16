
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.getNearest = functions.database.ref('/users/{pushId}/location').onWrite(event =>{
    const user = event.data.val(); //will give you the location of the user
    //console.log("latitude of currect user: " + user[0]);
    //console.log("latitude of currect user: " + user[1]);
    const userLat = user[0];
    const userLng = user[1];
    admin.database().ref('/spots/').once('value').then(function(snapshot) {
        snapshot.forEach(function(spotsSnapshot) {
            var lats = spotsSnapshot.val().latitude;
            var long = spotsSnapshot.val().longitude
        //    console.log(lats);
        //    console.log(long);
            var distance = getDistanceFromLatLonInKm(userLat,userLng,lats,long)
            console.log(distance);
            
        });
    });


    return ;
   //   return admin.database().ref('/users/').once('value').then(function(snapshot) {
 //       snapshot.forEach(function(userSnapshot) {
 //           var location = userSnapshot.val();
            //https://firebase.google.com/docs/reference/js/firebase.database.DataSnapshot
 //           console.log(location.location); //displaus emlocation of all users
            /*
            userSnapshot.child("location").forEach(function(element){ //this goes 1 layer deeper
            console.log(element.val())
            console.log("hi");
            });

            */
 //       });
        //var snap = snapshot.val(); //this gives you the list of all the users and their childrens        
        //console.log(snap);

//    });
}
);

function getDistanceFromLatLonInKm(lat1,lon1,lat2,lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat2-lat1);  // deg2rad below
    var dLon = deg2rad(lon2-lon1); 
    var a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2)
      ; 
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    var d = R * c; // Distance in km
    return d;
  }
  
  function deg2rad(deg) {
    return deg * (Math.PI/180)
  }




