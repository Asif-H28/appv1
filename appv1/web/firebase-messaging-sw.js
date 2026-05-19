importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBfQGymlUC2CnsxdB8YCl3_XlDJoGcTICk",
  appId: "1:846047241826:web:d4abc7f06c6ffb47f8133b",
  messagingSenderId: "846047241826",
  projectId: "schoolsync-b185a",
  authDomain: "schoolsync-b185a.firebaseapp.com",
  storageBucket: "schoolsync-b185a.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
  
  const title = (payload.notification && payload.notification.title) || 
                (payload.data && payload.data.title) || 
                "SchoolSync Notification";
                
  const body = (payload.notification && payload.notification.body) || 
               (payload.data && payload.data.body) || 
               "You have a new message.";

  const notificationOptions = {
    body: body,
    icon: "/favicon.png",
    data: payload.data
  };

  return self.registration.showNotification(title, notificationOptions);
});
