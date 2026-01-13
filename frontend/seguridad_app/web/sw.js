self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', () => {
  self.clients.claim();
});

self.addEventListener('message', event => {
  const { title, body } = event.data || {};
  if (!title) return;

  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
  });
});
