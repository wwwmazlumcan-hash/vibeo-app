{{flutter_js}}
{{flutter_build_config}}

(function () {
  if (!window._flutter || !window._flutter.loader) {
    document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;background:#03070D;color:#fff;font-family:Arial,sans-serif;padding:24px;text-align:center;">Flutter loader bulunamadi. Sayfayi yenileyin.</div>';
    return;
  }

  window._flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    }
  });
})();