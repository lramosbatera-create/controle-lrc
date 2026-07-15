const CACHE = 'lrc-v6';

self.addEventListener('install', e => {
  e.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  // Requisições de outra origem (Supabase, CDNs, etc.) vão direto à rede,
  // sem passar pelo cache do service worker — evita "Failed to fetch" em APIs externas
  if (new URL(e.request.url).origin !== self.location.origin) return;
  // Requests com ?bust= sempre vão direto à rede, ignorando qualquer cache
  if (e.request.url.includes('bust=')) {
    e.respondWith(fetch(e.request, {cache: 'no-store'}));
    return;
  }
  // HTML principal: sempre da rede, ignorando HTTP cache do browser
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request, {cache: 'no-store'}).catch(() => caches.match(e.request))
    );
    return;
  }
  // Outros recursos: cache-first com fallback na rede
  e.respondWith(
    caches.match(e.request).then(cached => {
      const net = fetch(e.request).then(res => {
        if (res.ok) caches.open(CACHE).then(c => c.put(e.request, res.clone()));
        return res;
      });
      return cached || net;
    })
  );
});
