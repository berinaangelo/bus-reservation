import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import * as operatorSession from '../api/operator/session'
import type { OperatorStaff } from '../types/operator'

const STORAGE_KEY = 'operator_session'

interface StoredSession {
  token: string
  staff: OperatorStaff
  expiresAt: string
}

// Token lives in localStorage, not a cookie: config/initializers/cors.rb does not set
// `credentials: true`, so the browser can't send/receive cookies cross-origin against this API.
export const useOperatorAuthStore = defineStore('operatorAuth', () => {
  const token = ref<string | null>(null)
  const staff = ref<OperatorStaff | null>(null)
  const expiresAt = ref<string | null>(null)

  const isAuthenticated = computed(
    () => !!token.value && !!expiresAt.value && new Date(expiresAt.value).getTime() > Date.now(),
  )

  function persist() {
    if (token.value && staff.value && expiresAt.value) {
      const stored: StoredSession = {
        token: token.value,
        staff: staff.value,
        expiresAt: expiresAt.value,
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(stored))
    } else {
      localStorage.removeItem(STORAGE_KEY)
    }
  }

  /** Restore a session from a previous page load. Call once, before mounting the app. */
  function hydrate() {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return
    try {
      const stored = JSON.parse(raw) as StoredSession
      token.value = stored.token
      staff.value = stored.staff
      expiresAt.value = stored.expiresAt
    } catch {
      localStorage.removeItem(STORAGE_KEY)
    }
  }

  async function login(email: string, password: string) {
    const res = await operatorSession.login(email, password)
    token.value = res.token
    staff.value = res.operator_staff
    expiresAt.value = res.expires_at
    persist()
  }

  /** Clears local state only — for the 401 handler, where the server session is already gone. */
  function clearSession() {
    token.value = null
    staff.value = null
    expiresAt.value = null
    persist()
  }

  /** Full logout — tells the server to invalidate the session, then clears locally regardless. */
  async function logout() {
    try {
      await operatorSession.logout()
    } finally {
      clearSession()
    }
  }

  /** Extends the session's expiry — used by the "stay logged in" prompt. Throws on failure
   *  (e.g. the session already lapsed server-side); the caller decides how to handle that. */
  async function renewSession() {
    const res = await operatorSession.renew()
    expiresAt.value = res.expires_at
    persist()
  }

  return {
    token,
    staff,
    expiresAt,
    isAuthenticated,
    hydrate,
    login,
    logout,
    clearSession,
    renewSession,
  }
})
