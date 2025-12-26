// Service Worker para funcionalidade offline
const CACHE_VERSION = 'crm-3k-v1';
const CACHE_ASSETS = [
  '/',
  '/offline.html',
  'https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css',
  'https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css',
  'https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js'
];

// Instalação do Service Worker
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Instalando...');

  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then((cache) => {
        console.log('[Service Worker] Cacheando assets essenciais');
        return cache.addAll(CACHE_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// Ativação do Service Worker
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Ativando...');

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_VERSION) {
            console.log('[Service Worker] Removendo cache antigo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Estratégia de cache: Network First com fallback para Cache
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Não cachear requisições POST/PUT/DELETE (mutações)
  if (request.method !== 'GET') {
    event.respondWith(
      fetch(request).catch(() => {
        // Se offline, armazenar para sincronização posterior
        return saveOfflineRequest(request);
      })
    );
    return;
  }

  // Strategy: Network First, fallback to Cache
  event.respondWith(
    fetch(request)
      .then((response) => {
        // Cachear resposta bem-sucedida
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open(CACHE_VERSION).then((cache) => {
            cache.put(request, responseClone);
          });
        }
        return response;
      })
      .catch(() => {
        // Se rede falhar, tentar cache
        return caches.match(request).then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }

          // Se não houver em cache, retornar página offline
          if (request.headers.get('accept').includes('text/html')) {
            return caches.match('/offline.html');
          }
        });
      })
  );
});

// Sincronização em background
self.addEventListener('sync', (event) => {
  console.log('[Service Worker] Background Sync disparado:', event.tag);

  if (event.tag === 'sync-offline-requests') {
    event.waitUntil(syncOfflineRequests());
  }
});

// Função para salvar requisições offline
async function saveOfflineRequest(request) {
  const requestData = {
    url: request.url,
    method: request.method,
    headers: Array.from(request.headers.entries()),
    body: await request.clone().text(),
    timestamp: Date.now()
  };

  // Armazenar no IndexedDB
  const db = await openOfflineDB();
  const tx = db.transaction('offline-requests', 'readwrite');
  tx.objectStore('offline-requests').add(requestData);

  // Registrar sincronização
  if ('sync' in self.registration) {
    await self.registration.sync.register('sync-offline-requests');
  }

  return new Response(JSON.stringify({
    message: 'Operação salva. Será sincronizada quando reconectar.',
    offline: true
  }), {
    status: 202,
    headers: { 'Content-Type': 'application/json' }
  });
}

// Sincronizar requisições offline
async function syncOfflineRequests() {
  const db = await openOfflineDB();
  const tx = db.transaction('offline-requests', 'readonly');
  const requests = await tx.objectStore('offline-requests').getAll();

  console.log(`[Service Worker] Sincronizando ${requests.length} requisições offline`);

  for (const req of requests) {
    try {
      const headers = new Headers(req.headers);

      const response = await fetch(req.url, {
        method: req.method,
        headers: headers,
        body: req.body
      });

      if (response.ok) {
        // Remover da fila após sucesso
        const deleteTx = db.transaction('offline-requests', 'readwrite');
        await deleteTx.objectStore('offline-requests').delete(req.id);

        console.log('[Service Worker] Sincronizado com sucesso:', req.url);
      }
    } catch (error) {
      console.error('[Service Worker] Erro ao sincronizar:', error);
    }
  }
}

// Abrir IndexedDB para armazenar requisições offline
function openOfflineDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('crm-offline-db', 1);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('offline-requests')) {
        const store = db.createObjectStore('offline-requests', {
          keyPath: 'id',
          autoIncrement: true
        });
        store.createIndex('timestamp', 'timestamp', { unique: false });
      }
    };
  });
}

// Notificações de sincronização
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
