export class ApiError extends Error {
  status: number
  fieldErrors?: Record<string, string[]>

  constructor(status: number, message: string, fieldErrors?: Record<string, string[]>) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.fieldErrors = fieldErrors
  }
}

// Shared by every paginated operator-admin list endpoint (trips/routes/bus_units/fare_rules/
// manifest), all via Pagy::Method — { page, pages, count }.
export interface PaginationMeta {
  page: number
  pages: number
  count: number
}

// e.g. PaginatedResponse<'routes', OperatorRoute> => { routes: OperatorRoute[]; meta: PaginationMeta }
export type PaginatedResponse<K extends string, T> = { meta: PaginationMeta } & Record<K, T[]>
