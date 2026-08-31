<script setup lang="ts">
// See kos/decisions/ux/mockups/operator-dashboard.html (Sidebar + Table, chosen) — same
// list+drawer shape as the other operator-admin screens, applied to staff onboarding.
import { onMounted, ref } from 'vue'
import { listStaff, inviteStaff, updateStaffActive } from '../../api/operator/staff'
import type { OperatorStaffMember } from '../../types/operator'
import { ApiError } from '../../api/types'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseToast from '../../components/ui/BaseToast.vue'
import BaseDialog from '../../components/ui/BaseDialog.vue'
import BaseDrawer from '../../components/ui/BaseDrawer.vue'
import Empty from '../../components/ui/Empty.vue'

const staff = ref<OperatorStaffMember[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)

const drawerOpen = ref(false)
const inviteName = ref('')
const inviteEmail = ref('')
const inviteErrors = ref<Record<string, string[]>>({})
const inviting = ref(false)
const successMessage = ref<string | null>(null)

const confirmingId = ref<number | null>(null)
const togglingId = ref<number | null>(null)

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const res = await listStaff()
    staff.value = res.staff
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : 'Could not load staff. Try again.'
  } finally {
    loading.value = false
  }
}

onMounted(load)

function openDrawer() {
  inviteName.value = ''
  inviteEmail.value = ''
  inviteErrors.value = {}
  drawerOpen.value = true
}

async function onInvite() {
  inviteErrors.value = {}
  inviting.value = true
  try {
    await inviteStaff(inviteName.value, inviteEmail.value)
    drawerOpen.value = false
    successMessage.value = `Invited ${inviteName.value}. They'll get an email to set their password.`
    await load()
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      inviteErrors.value = e.fieldErrors
    } else {
      inviteErrors.value = {
        email: [e instanceof ApiError ? e.message : 'Something went wrong. Try again.'],
      }
    }
  } finally {
    inviting.value = false
  }
}

async function toggleActive(member: OperatorStaffMember) {
  togglingId.value = member.id
  try {
    await updateStaffActive(member.id, !member.active)
    confirmingId.value = null
    await load()
  } finally {
    togglingId.value = null
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <h1 class="font-display text-2xl font-bold">Staff</h1>
      <BaseButton variant="primary" size="sm" @click="openDrawer">Invite staff</BaseButton>
    </div>

    <BaseToast
      v-if="successMessage"
      variant="success"
      :message="successMessage"
      class="mb-4"
      @dismiss="successMessage = null"
    />
    <BaseToast
      v-if="loadError"
      variant="danger"
      :message="loadError"
      :dismissible="false"
      class="mb-4"
    />

    <p v-if="loading" class="text-sm text-muted">Loading…</p>

    <Empty
      v-else-if="staff.length === 0 && !loadError"
      size="md"
      title="No staff yet"
      message="Invite a coworker to give them access to this console."
    />

    <div v-else class="border border-border bg-surface overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-border text-left">
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Name
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Email
            </th>
            <th class="font-display uppercase tracking-wider text-[11px] text-muted px-4 py-3">
              Status
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="member in staff"
            :key="member.id"
            class="border-b border-border last:border-b-0"
          >
            <td class="px-4 py-3">{{ member.name }}</td>
            <td class="px-4 py-3 text-muted">{{ member.email }}</td>
            <td class="px-4 py-3">
              <span :class="member.active ? 'text-success' : 'text-muted'">
                {{ member.active ? 'Active' : 'Inactive' }}
              </span>
              <span v-if="member.locked" class="text-warning ml-2">Locked</span>
            </td>
            <td class="px-4 py-3 text-right">
              <BaseDialog
                v-if="confirmingId === member.id"
                layout="inline"
                :variant="member.active ? 'danger' : 'primary'"
                :message="`${member.active ? 'Deactivate' : 'Reactivate'} ${member.name}?`"
                :confirm-label="member.active ? 'Deactivate' : 'Reactivate'"
                :loading="togglingId === member.id"
                @confirm="toggleActive(member)"
                @cancel="confirmingId = null"
              />
              <BaseButton
                v-else
                :variant="member.active ? 'danger' : 'secondary'"
                size="sm"
                @click="confirmingId = member.id"
              >
                {{ member.active ? 'Deactivate' : 'Reactivate' }}
              </BaseButton>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <BaseDrawer v-model="drawerOpen" title="Invite staff" :persistent="inviting">
      <form @submit.prevent="onInvite">
        <BaseInput
          id="invite-name"
          v-model="inviteName"
          label="Name"
          required
          :error="inviteErrors.name?.[0]"
          class="mb-3"
        />
        <BaseInput
          id="invite-email"
          v-model="inviteEmail"
          type="email"
          label="Email"
          required
          :error="inviteErrors.email?.[0]"
          class="mb-4"
        />
        <BaseButton
          type="submit"
          variant="primary"
          class="w-full"
          :loading="inviting"
          loading-text="Inviting…"
        >
          Send invite
        </BaseButton>
      </form>
    </BaseDrawer>
  </div>
</template>
