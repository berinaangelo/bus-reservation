import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { installGuards } from './guards'

import RiderLayout from '../layouts/RiderLayout.vue'
import OperatorLayout from '../layouts/OperatorLayout.vue'

import TripSearchView from '../views/rider/TripSearchView.vue'
import TripSearchResultsView from '../views/rider/TripSearchResultsView.vue'
import SeatSelectionView from '../views/rider/SeatSelectionView.vue'
import ETicketConfirmationView from '../views/rider/ETicketConfirmationView.vue'
import BookingLookupView from '../views/rider/BookingLookupView.vue'
import BookingDetailView from '../views/rider/BookingDetailView.vue'

import OperatorLoginView from '../views/operator/OperatorLoginView.vue'
import OperatorRoutesView from '../views/operator/OperatorRoutesView.vue'
import OperatorTripsView from '../views/operator/OperatorTripsView.vue'
import OperatorBusUnitsView from '../views/operator/OperatorBusUnitsView.vue'
import OperatorFareRulesView from '../views/operator/OperatorFareRulesView.vue'
import TripManifestView from '../views/operator/TripManifestView.vue'

import NotFoundView from '../views/NotFoundView.vue'

declare module 'vue-router' {
  interface RouteMeta {
    requiresOperatorAuth?: boolean
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    component: RiderLayout,
    children: [
      { path: '', redirect: { name: 'trip-search' } },
      { path: 'trips/search', name: 'trip-search', component: TripSearchView },
      { path: 'trips/results', name: 'trip-search-results', component: TripSearchResultsView },
      {
        path: 'trips/:tripId/seats',
        name: 'seat-selection',
        component: SeatSelectionView,
        props: true,
      },
      {
        path: 'bookings/confirmation/:referenceCode',
        name: 'e-ticket',
        component: ETicketConfirmationView,
        props: true,
      },
      { path: 'bookings/lookup', name: 'booking-lookup', component: BookingLookupView },
      {
        path: 'bookings/:referenceCode',
        name: 'booking-detail',
        component: BookingDetailView,
        props: true,
      },
    ],
  },
  {
    path: '/operator/login',
    name: 'operator-login',
    component: OperatorLoginView,
  },
  {
    path: '/operator',
    component: OperatorLayout,
    meta: { requiresOperatorAuth: true },
    children: [
      { path: '', redirect: { name: 'operator-routes' } },
      { path: 'routes', name: 'operator-routes', component: OperatorRoutesView },
      { path: 'trips', name: 'operator-trips', component: OperatorTripsView },
      {
        path: 'trips/:tripId/manifest',
        name: 'trip-manifest',
        component: TripManifestView,
        props: true,
      },
      { path: 'bus-units', name: 'operator-bus-units', component: OperatorBusUnitsView },
      { path: 'fare-rules', name: 'operator-fare-rules', component: OperatorFareRulesView },
    ],
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: NotFoundView },
]

if (import.meta.env.DEV) {
  routes.push({
    path: '/dev/ui-kit',
    name: 'dev-ui-kit',
    component: () => import('../views/dev/UiKitPreviewView.vue'),
  })
}

export const router = createRouter({
  history: createWebHistory(),
  routes,
})

installGuards(router)
