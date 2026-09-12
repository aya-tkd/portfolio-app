import { test, afterEach } from 'node:test'
import assert from 'node:assert/strict'
import { loadPatient, savePatient } from '../src/features/patients/api.js'
import { loadDepartment, saveDepartment } from '../src/features/administration/departments/api.js'
import { ApiError } from '../src/shared/api/http.js'
const realFetch = globalThis.fetch
afterEach(() => { globalThis.fetch = realFetch })

test('save obtains CSRF token and sends JSON with no automatic retry', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => {
    calls.push([url, options])
    return { ok: true, json: async () => calls.length === 1 ? { token: 'test-only' } : { id: 1 } }
  }
  assert.deepEqual(await savePatient(null, { first_name: 'デモ' }), { id: 1 })
  assert.equal(calls[1][1].headers['X-CSRF-Token'], 'test-only')
  assert.equal(calls[1][1].method, 'POST')
  assert.equal(calls[1][1].credentials, 'same-origin')
})
test('422 errors are preserved', async () => {
  globalThis.fetch = async () => ({ ok: false, status: 422, json: async () => ({ errors: { last_name: ['入力してください。'] } }) })
  await assert.rejects(loadPatient(1), error => error instanceof ApiError && error.errors.last_name.length === 1)
})
test('network failure is not retried', async () => {
  let calls = 0
  globalThis.fetch = async () => { calls++; throw new TypeError('network') }
  await assert.rejects(savePatient(1, {}))
  assert.equal(calls, 1)
})
test('department API obtains CSRF and uses the resource-specific URL', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => {
    calls.push([url, options])
    return { ok: true, json: async () => calls.length === 1 ? { token: 'test-only' } : { id: 1, name: '内科' } }
  }
  assert.deepEqual(await saveDepartment(null, { name: '内科' }), { id: 1, name: '内科' })
  assert.equal(calls[1][0], '/api/departments')
  assert.equal(calls[1][1].method, 'POST')
  assert.equal(calls[1][1].headers['X-CSRF-Token'], 'test-only')
  globalThis.fetch = async () => ({ ok: true, json: async () => ({ id: 1 }) })
  assert.deepEqual(await loadDepartment(1), { id: 1 })
})
