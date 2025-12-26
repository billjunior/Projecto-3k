// Sistema de sincronização offline para CRM 3K
class OfflineSync {
  constructor() {
    this.db = null;
    this.syncInProgress = false;
    this.init();
  }

  async init() {
    // Registrar Service Worker
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/service-worker.js');
        console.log('[Offline Sync] Service Worker registrado:', registration.scope);

        // Atualizar quando novo SW disponível
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              this.showUpdateNotification();
            }
          });
        });
      } catch (error) {
        console.error('[Offline Sync] Erro ao registrar Service Worker:', error);
      }
    }

    // Abrir IndexedDB local
    this.db = await this.openDB();

    // Monitorar conectividade
    this.setupConnectivityMonitoring();

    // Tentar sincronizar ao carregar
    if (navigator.onLine) {
      this.syncPendingData();
    }
  }

  openDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('crm-offline-data', 1);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);

      request.onupgradeneeded = (event) => {
        const db = event.target.result;

        // Store para dados pendentes de sincronização
        if (!db.objectStoreNames.contains('pending-sync')) {
          const store = db.createObjectStore('pending-sync', {
            keyPath: 'id',
            autoIncrement: true
          });
          store.createIndex('timestamp', 'timestamp', { unique: false });
          store.createIndex('type', 'type', { unique: false });
        }

        // Store para cache de dados
        if (!db.objectStoreNames.contains('cached-data')) {
          const store = db.createObjectStore('cached-data', { keyPath: 'key' });
          store.createIndex('timestamp', 'timestamp', { unique: false });
        }
      };
    });
  }

  setupConnectivityMonitoring() {
    // Detectar quando voltar online
    window.addEventListener('online', () => {
      console.log('[Offline Sync] Conexão restabelecida');
      this.showNotification('Conexão restabelecida', 'Sincronizando dados...', 'success');
      this.syncPendingData();
    });

    // Detectar quando ficar offline
    window.addEventListener('offline', () => {
      console.log('[Offline Sync] Conexão perdida');
      this.showNotification('Sem conexão', 'Trabalhando offline. Dados serão sincronizados quando reconectar.', 'warning');
    });

    // Atualizar indicador de status
    this.updateConnectionStatus();
    setInterval(() => this.updateConnectionStatus(), 5000);
  }

  updateConnectionStatus() {
    const indicator = document.getElementById('connection-status');
    if (!indicator) return;

    if (navigator.onLine) {
      indicator.innerHTML = '<i class="bi bi-wifi"></i> Online';
      indicator.className = 'connection-status online';
    } else {
      indicator.innerHTML = '<i class="bi bi-wifi-off"></i> Offline';
      indicator.className = 'connection-status offline';
    }
  }

  async savePendingOperation(type, url, data) {
    const operation = {
      type: type,
      url: url,
      data: data,
      timestamp: Date.now()
    };

    const tx = this.db.transaction('pending-sync', 'readwrite');
    await tx.objectStore('pending-sync').add(operation);

    console.log('[Offline Sync] Operação salva para sincronização:', operation);

    this.showNotification('Operação salva', 'Será sincronizada quando reconectar', 'info');
  }

  async syncPendingData() {
    if (this.syncInProgress || !navigator.onLine) {
      return;
    }

    this.syncInProgress = true;
    console.log('[Offline Sync] Iniciando sincronização...');

    try {
      const tx = this.db.transaction('pending-sync', 'readonly');
      const operations = await tx.objectStore('pending-sync').getAll();

      if (operations.length === 0) {
        console.log('[Offline Sync] Nenhuma operação pendente');
        this.syncInProgress = false;
        return;
      }

      console.log(`[Offline Sync] Sincronizando ${operations.length} operações`);

      let successCount = 0;
      let failCount = 0;

      for (const op of operations) {
        try {
          const response = await fetch(op.url, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
            },
            body: JSON.stringify(op.data)
          });

          if (response.ok) {
            // Remover da fila
            const deleteTx = this.db.transaction('pending-sync', 'readwrite');
            await deleteTx.objectStore('pending-sync').delete(op.id);
            successCount++;
          } else {
            failCount++;
          }
        } catch (error) {
          console.error('[Offline Sync] Erro ao sincronizar operação:', error);
          failCount++;
        }
      }

      if (successCount > 0) {
        this.showNotification(
          'Sincronização concluída',
          `${successCount} operação(ões) sincronizada(s) com sucesso${failCount > 0 ? `, ${failCount} falharam` : ''}`,
          'success'
        );
      }

    } catch (error) {
      console.error('[Offline Sync] Erro na sincronização:', error);
    } finally {
      this.syncInProgress = false;
    }
  }

  async cacheData(key, data) {
    const tx = this.db.transaction('cached-data', 'readwrite');
    await tx.objectStore('cached-data').put({
      key: key,
      data: data,
      timestamp: Date.now()
    });
  }

  async getCachedData(key) {
    const tx = this.db.transaction('cached-data', 'readonly');
    const result = await tx.objectStore('cached-data').get(key);
    return result?.data;
  }

  showNotification(title, message, type = 'info') {
    // Criar notificação toast
    const toastContainer = document.getElementById('toast-container') || this.createToastContainer();

    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type === 'success' ? 'success' : type === 'warning' ? 'warning' : type === 'error' ? 'danger' : 'info'} border-0`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">
          <strong>${title}</strong><br>${message}
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;

    toastContainer.appendChild(toast);

    const bsToast = new bootstrap.Toast(toast, { delay: 5000 });
    bsToast.show();

    toast.addEventListener('hidden.bs.toast', () => toast.remove());
  }

  createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container position-fixed top-0 end-0 p-3';
    container.style.zIndex = '9999';
    document.body.appendChild(container);
    return container;
  }

  showUpdateNotification() {
    const notification = confirm(
      'Uma nova versão do CRM 3K está disponível. Deseja atualizar agora?'
    );

    if (notification && navigator.serviceWorker.controller) {
      navigator.serviceWorker.controller.postMessage({ type: 'SKIP_WAITING' });
      window.location.reload();
    }
  }
}

// Inicializar quando DOM carregar
document.addEventListener('DOMContentLoaded', () => {
  window.offlineSync = new OfflineSync();
});

// Exportar para uso global
window.OfflineSync = OfflineSync;
