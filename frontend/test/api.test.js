import { test, afterEach } from 'node:test'
import assert from 'node:assert/strict'
import { loadPatient, savePatient, searchPatients } from '../src/features/patients/api.js'
import { loadDepartment, saveDepartment, searchDepartments } from '../src/features/administration/departments/api.js'
import { loadOccupation, saveOccupation, searchOccupations } from '../src/features/administration/occupations/api.js'
import { loadUser, saveUser, searchUsers } from '../src/features/administration/users/api.js'
import { loadReceptionCandidates, registerReceptions } from '../src/features/receptions/api.js'
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
test('patient search sends supplied conditions as a read-only query URL', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => {
    calls.push([url, options])
    return { ok: true, json: async () => [] }
  }
  assert.deepEqual(await searchPatients({ patientNumber: 'P-100', name: '山田 太郎' }), [])
  assert.equal(calls[0][0], '/api/patients?patient_number=P-100&name=%E5%B1%B1%E7%94%B0+%E5%A4%AA%E9%83%8E')
  assert.equal(calls[0][1].method, undefined)
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
test('occupation API uses its own resource URL', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => { calls.push([url, options]); return { ok: true, json: async () => calls.length === 1 ? { token: 'test-only' } : { id: 1, name: '医師' } } }
  assert.deepEqual(await saveOccupation(null, { name: '医師' }), { id: 1, name: '医師' })
  assert.equal(calls[1][0], '/api/occupations')
  globalThis.fetch = async () => ({ ok: true, json: async () => ({ id: 1 }) })
  assert.deepEqual(await loadOccupation(1), { id: 1 })
})
test('master list APIs issue read-only search URLs only for supplied conditions', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => { calls.push([url, options]); return { ok: true, json: async () => [] } }
  await searchDepartments({ keyword: '内科', active: 'true' })
  await searchOccupations()
  assert.equal(calls[0][0], '/api/departments?keyword=%E5%86%85%E7%A7%91&active=true')
  assert.equal(calls[0][1].method, undefined)
  assert.equal(calls[1][0], '/api/occupations')
})
test('user API searches by all supplied conditions and saves through its resource URL', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => { calls.push([url, options]); return { ok: true, json: async () => calls.length === 2 ? { token: 'test-only' } : { id: 9 } } }
  await searchUsers({ userId: '9', name: '山田 太郎', departmentId: '1', occupationId: '2' })
  assert.equal(calls[0][0], '/api/users?user_id=9&name=%E5%B1%B1%E7%94%B0+%E5%A4%AA%E9%83%8E&department_id=1&occupation_id=2')
  assert.deepEqual(await saveUser(null, { first_name: '太郎' }), { id: 9 })
  assert.equal(calls[2][0], '/api/users')
  assert.equal(calls[2][1].headers['X-CSRF-Token'], 'test-only')
  globalThis.fetch = async () => ({ ok: true, json: async () => ({ id: 9 }) })
  assert.deepEqual(await loadUser(9), { id: 9 })
})

test('reception API obtains candidates and posts selected doctor user IDs', async () => {
  const calls = []
  globalThis.fetch = async (url, options) => {
    calls.push([url, options])
    if (calls.length === 1) return { ok: true, json: async () => ({ doctor_users: [{ id: 12, name: '医師 太郎' }] }) }
    if (calls.length === 2) return { ok: true, json: async () => ({ token: 'test-only' }) }
    return { ok: true, json: async () => ({ receptions: [{ id: 1 }] }) }
  }

  assert.deepEqual(await loadReceptionCandidates(7), { doctor_users: [{ id: 12, name: '医師 太郎' }] })
  assert.deepEqual(await registerReceptions({ patient_id: 7, targets: [{ type: 'unreserved', department_id: 3, doctor_user_id: 12 }] }), { receptions: [{ id: 1 }] })
  assert.equal(calls[0][0], '/api/patients/7/reception_candidates')
  assert.equal(calls[2][0], '/api/receptions')
  assert.equal(calls[2][1].headers['X-CSRF-Token'], 'test-only')
  assert.deepEqual(JSON.parse(calls[2][1].body), { reception: { patient_id: 7, targets: [{ type: 'unreserved', department_id: 3, doctor_user_id: 12 }] } })
})
