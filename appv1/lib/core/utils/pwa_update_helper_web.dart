import 'dart:js' as js;

/// Web implementation of PWA update that communicates with the service worker.
void triggerPwaUpdate() {
  js.context.callMethod('eval', [
    '''
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistration().then(function(reg) {
        if (reg) {
          if (reg.waiting) {
            reg.waiting.postMessage({type: 'SKIP_WAITING'});
          }
          reg.update().then(function() {
            window.location.reload();
          }).catch(function() {
            window.location.reload();
          });
        } else {
          window.location.reload();
        }
      }).catch(function() {
        window.location.reload();
      });
    } else {
      window.location.reload();
    }
    '''
  ]);
}
