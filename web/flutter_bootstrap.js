{{flutter_js}}
{{flutter_build_config}}

(async function () {
  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));

      if ('caches' in window) {
        const cacheKeys = await caches.keys();
        await Promise.all(cacheKeys.map((cacheKey) => caches.delete(cacheKey)));
      }
    } catch (error) {
      console.warn('Service worker temizlenemedi:', error);
    }
  }

  if (!window._flutter || !window._flutter.loader) {
    document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;background:#03070D;color:#fff;font-family:Arial,sans-serif;padding:24px;text-align:center;">Flutter loader bulunamadi. Sayfayi yenileyin.</div>';
    return;
  }

  window._flutter.loader.load({
    serviceWorkerSettings: null,
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    }
  });
})();