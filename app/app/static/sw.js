/* BoatBox service worker. Modern iOS caches the shell; old iOS simply ignores this. */
var CACHE='boatbox-v3';
var CORE=['/','/captain','/remote','/ios','/display','/static/manifest.json','/static/icons/boatbox-180.png'];
self.addEventListener('install',function(e){e.waitUntil(caches.open(CACHE).then(function(c){return c.addAll(CORE)}));});
self.addEventListener('activate',function(e){e.waitUntil(caches.keys().then(function(keys){return Promise.all(keys.map(function(k){if(k!==CACHE)return caches.delete(k)}));}));});
self.addEventListener('fetch',function(e){
  var url=new URL(e.request.url);
  if(url.pathname.indexOf('/api/')===0 || url.pathname.indexOf('/upload')===0){return;}
  e.respondWith(fetch(e.request).then(function(r){var copy=r.clone();caches.open(CACHE).then(function(c){c.put(e.request,copy)});return r;}).catch(function(){return caches.match(e.request).then(function(r){return r || caches.match('/');});}));
});
