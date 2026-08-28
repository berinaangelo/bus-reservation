import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import { router } from './router'
import { useOperatorAuthStore } from './stores/operatorAuth'

const app = createApp(App)

app.use(createPinia())

// Restore a persisted operator session before the router's first navigation guard runs, so a
// page reload doesn't briefly bounce an authenticated operator to /operator/login.
useOperatorAuthStore().hydrate()

app.use(router)

app.mount('#app')
