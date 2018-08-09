
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const token = 'sk_test_igto1DWjcLtPJEPexiGyvZgB'
const customCurrency = 'USD'
admin.initializeApp(functions.config().firebase);

const stripe = require('stripe')(token),
      currency = customCurrency || 'USD';

exports.createEphemeralKey = functions.database.ref('/users/{userId}/stripe/api_version').onWrite(event => {
  var api = event.data.val(); // gives us api version
//  var cust_id = event.val();  this doesnt work
//  console.log(event);
//  console.log(api);
  return admin.database().ref(`/users/${event.params.userId}/stripe/customer_id`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
//      console.log(customer);
//      console.log(customer.val());
        const cust_id = customer;
        console.log('api: ' , api);
        stripe.ephemeralKeys.create(
          {customer: cust_id},
          {stripe_version: "2015-10-12"}
        ).then((key) => {
          //res.status(200).json(key);
          //console.log(key);
          return event.data.ref.parent.child('ephemeral_key').set(key);
        }).catch((err) => {
          //console.log(key);
          //res.status(500).end();
        });
  });

});      
/*  stripe.ephemeralKeys.create(
    {customer: req.customerId},
    {stripe_version: stripe_version}
  ).then((key) => {
    res.status(200).json(key);
  }).catch((err) => {
    res.status(500).end();
  });
*/
      
// [START chargecustomer]
// Charge the Stripe customer whenever an amount is written to the Realtime database
exports.createStripeCharge = functions.database.ref('/users/{userId}/stripe/charges/{id}').onWrite(event => {
  const val = event.data.val();
  const data = event.data;
  //console.log(val)
  // This onWrite will trigger whenever anything is written to the path, so
  // noop if the charge was deleted, errored out, or the Stripe API returned a result (id exists) 
  if (val === null || val.id || val.error) return null;
  // Look up the Stripe customer id written in createStripeCustomer
  return admin.database().ref(`/users/${event.params.userId}/stripe/customer_id`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    console.log(customer); //gives us customer id
    const amount = val.amount;
    const currency = "cad";
    
    const source = val.source;
    let charge = {amount, currency, customer};
    if (val.source !== null) charge.source = val.source;
    let charge_obj = stripe.charges.create({
      amount: amount,
      currency: currency,
      source: source, // obtained with Stripe.js
      customer: customer,
      description: "Charge for benjamin.robinson@example.com"
    }).then( chrge => {
    
      //console.log(charges.uid);
      return event.data.ref.set(chrge);
      //return admin.database().ref(`/users/${data.uid}/stripe/charges/${val.uid}`).set(chrge);
    });
    
  });
});

// When a user is created, register them with Stripe

exports.createStripeCustomer = functions.auth.user().onCreate(event => {
  const data = event.data;
  return stripe.customers.create({
    email: data.email
  }).then(customer => {
    return admin.database().ref(`/users/${data.uid}/stripe/customer_id`).set(customer.id);
  });
});

// Add a payment source (card) for a user by writing a stripe payment source token to Realtime database
exports.addPaymentSource = functions.database.ref('/users/{userId}/sources/{pushId}/token').onWrite(event => {
  const source = event.data.val();
  if (source === null) return null;
  return admin.database().ref(`/users/${event.params.userId}/customer_id`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    return stripe.customers.createSource(customer, {source});
  }).then(response => {
      return event.data.adminRef.parent.set(response);
    }, error => {
      return event.data.adminRef.parent.child('error').set(userFacingMessage(error)).then(() => {
        return reportError(error, {user: event.params.userId});
      });
  });
});

// When a user deletes their account, clean up after them
exports.cleanupUser = functions.auth.user().onDelete(event => {
  return admin.database().ref(`/users/${event.data.uid}`).once('value').then(snapshot => {
    return snapshot.val();
  }).then(customer => {
    return stripe.customers.del(customer.customer_id);
  }).then(() => {
    return admin.database().ref(`/users/${event.data.uid}`).remove();
  });
});

function reportError(err, context = {}) {
  const logName = 'errors';
  const log = logging.log(logName);

  // https://cloud.google.com/logging/docs/api/ref_v2beta1/rest/v2beta1/MonitoredResource
  const metadata = {
    resource: {
      type: 'cloud_function',
      labels: { function_name: process.env.FUNCTION_NAME }
    }
  };

  // https://cloud.google.com/error-reporting/reference/rest/v1beta1/ErrorEvent
  const errorEvent = {
    message: err.stack,
    serviceContext: {
      service: process.env.FUNCTION_NAME,
      resourceType: 'cloud_function'
    },
    context: context
  };

  // Write the error log entry
  return new Promise((resolve, reject) => {
    log.write(log.entry(metadata, errorEvent), error => {
      if (error) { reject(error); }
      resolve();
    });
  });
}

// Sanitize the error message for the user
function userFacingMessage(error) {
  return error.type ? error.message : 'An error occurred, developers have been alerted';
}


// Take the text parameter passed to this HTTP endpoint and insert it into the
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




