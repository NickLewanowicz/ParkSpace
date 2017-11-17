
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.getNearest = functions.database.ref('/users/{pushId}/location').onWrite(event =>{
    const user = event.data.val(); //will give you the location of the current user. [lat, lng]
    const userLat = user[0];
    const userLng = user[1];
    var   nearBySpots = new Array();
    return admin.database().ref('/spots/').once('value').then(function(snapshot) {
        snapshot.forEach(function(spotsSnapshot) {
            var lats = spotsSnapshot.val().latitude;
            var long = spotsSnapshot.val().longitude;
            var distance = getDistanceFromLatLonInKm(userLat,userLng,lats,long);

            if(distance <= 10){ //within 10km
                console.log("Added spotID: " + spotsSnapshot.key + " distance: " + distance);
                nearBySpots.push(spotsSnapshot.key);               
            }      
        });
        console.log("array length = " + nearBySpots.length);
        return event.data.ref.parent.child('nearbySpots').set(nearBySpots);
    });
});

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




