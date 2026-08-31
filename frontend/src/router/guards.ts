import type { Router } from 'vue-router'
import { useOperatorAuthStore } from '../stores/operatorAuth'

export function installGuards(router: Router) {
  router.beforeEach((to) => {
    const auth = useOperatorAuthStore()

    if (to.meta.requiresOperatorAuth && !auth.isAuthenticated) {
      return { name: 'operator-login', query: { redirect: to.fullPath } }
    }

    if (to.meta.guestOnly && auth.isAuthenticated) {
      return { name: 'operator-routes' }
    }
  })
}
