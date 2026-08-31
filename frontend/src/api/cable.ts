import { createConsumer, type Consumer } from '@rails/actioncable'
import { useOperatorAuthStore } from '../stores/operatorAuth'

// Mirrors client.ts's BASE_URL story: empty in dev so the relative /cable path hits Vite's dev
// proxy (vite.config.ts), which forwards the WebSocket upgrade to ws://localhost:3000 — must be
// set for any production build, same as VITE_API_BASE_URL. The bearer token rides as a query
// param, not an Authorization header: a raw WebSocket handshake can't carry custom headers, so
// app/channels/application_cable/connection.rb authenticates via request.params[:token] instead.
const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? ''

let consumer: Consumer | null = null
let consumerToken: string | null = null

export function getConsumer(): Consumer {
  const token = useOperatorAuthStore().token

  // A stale consumer was authenticated with whatever token was current at connect time --
  // ActionCable::Connection::Base only authenticates once, on the initial handshake. Reuse the
  // existing connection as long as the token hasn't changed (the common case: every manifest
  // view mount would otherwise tear down and reconnect for no reason); only rebuild when it has
  // (a renewed session or re-login issues a new token).
  if (consumer && token === consumerToken) return consumer

  if (consumer) consumer.disconnect()

  const url = new URL(`${BASE_URL}/cable`, window.location.origin)
  url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:'
  if (token) url.searchParams.set('token', token)

  consumer = createConsumer(url.toString())
  consumerToken = token
  return consumer
}
