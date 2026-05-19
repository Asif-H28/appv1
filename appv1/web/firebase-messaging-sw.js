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
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png"
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
