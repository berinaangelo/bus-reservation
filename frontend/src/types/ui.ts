// Shared types for the base UI component kit (frontend/src/components/ui/).
// Grouped here (rather than colocated per-component) because more than one component's props
// reference the same union — e.g. BaseDialog maps its own `variant`/`layout` onto BaseButton's.

export interface SelectOption<T> {
  label: string
  value: T
}

export type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'danger-filled'
export type ButtonSize = 'sm' | 'md'
export type DialogVariant = 'primary' | 'danger'
export type DialogLayout = 'stacked' | 'inline'
export type ToastVariant = 'danger' | 'success' | 'warning' | 'info'
