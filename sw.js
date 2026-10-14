const CACHE='contacts-v2';
const STATIC=['./manifest.webmanifest','./icon.svg'];
self.addEventListener('install',event=>{
  event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(STATIC)).then(()=>self.skipWaiting()));
});
self.addEventListener('activate',event=>{
  event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});
self.addEventListener('fetch',event=>{
  if(event.request.method!=='GET') return;
  const url=new URL(event.request.url);
  if(url.origin===self.location.origin && (url.pathname.endsWith('/config.js') || url.pathname.endsWith('/index.html') || url.pathname.endsWith('/'))){
    event.respondWith(fetch(event.request).catch(()=>caches.match(event.request)));
    return;
  }
  event.respondWith(caches.match(event.request).then(cached=>cached||fetch(event.request).then(resp=>{
    if(url.origin===self.location.origin){const copy=resp.clone();caches.open(CACHE).then(c=>c.put(event.request,copy));}
    return resp;
  })));
});
