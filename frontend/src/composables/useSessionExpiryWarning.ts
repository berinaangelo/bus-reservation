// Proactively watches the operator session's expiresAt so an operator gets a warning — and a way
// to extend the session — before being bounced mid-task. Nothing else in the app watches expiry
// proactively: the store's `isAuthenticated` getter and the router guard are both reactive/pull
// based, only re-checked on navigation or the next API call.
import { ref, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useOperatorAuthStore } from '../stores/operatorAuth'

const CHECK_INTERVAL_MS = 30_000
const WARNING_THRESHOLD_MS = 5 * 60_000

export function useSessionExpiryWarning() {
  const auth = useOperatorAuthStore()
  const router = useRouter()

  const showWarning = ref(false)
  const renewing = ref(false)

  async function expireNow() {
    auth.clearSession()
    showWarning.value = false
    await router.push({ name: 'operator-login', query: { reason: 'expired' } })
  }

  function check() {
    if (!auth.isAuthenticated || !auth.expiresAt) {
      showWarning.value = false
      return
    }
    const remaining = new Date(auth.expiresAt).getTime() - Date.now()
    if (remaining <= 0) {
      void expireNow()
      return
    }
    showWarning.value = remaining <= WARNING_THRESHOLD_MS
  }

  async function renew() {
    renewing.value = true
    try {
      await auth.renewSession()
      showWarning.value = false
    } catch {
      // Renewal failing (e.g. the session already lapsed server-side) means the same thing as
      // the timer hitting zero.
      await expireNow()
    } finally {
      renewing.value = false
    }
  }

  const intervalId = window.setInterval(check, CHECK_INTERVAL_MS)
  check()

  onUnmounted(() => window.clearInterval(intervalId))

  return { showWarning, renewing, renew }
}
