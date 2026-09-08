// 業務に依存しないHTTPの仕組み。患者・予約などのURLや保存項目はここへ置かない。
// HTTPエラーと通信障害を区別して、呼び出し元が入力保持を判断できるようにする。
export class ApiError extends Error {
  constructor(message, status, errors = {}) { super(message); this.status = status; this.errors = errors }
}

export async function request(path, options = {}) {
  // 15秒で打ち切るが、サーバー処理の取り消しは保証しない。自動再送はしない。
  const response = await fetch(path, { credentials: 'same-origin', signal: AbortSignal.timeout(15000), ...options })
  const body = await response.json()
  if (!response.ok) throw new ApiError(body.message || '入力内容を確認してください。', response.status, body.errors)
  return body
}
