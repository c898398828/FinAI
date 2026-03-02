import request from './request'

export const authApi = {
  login(data: { username: string; password: string }) {
    return request.post('/auth/login', data)
  },
  register(data: { username: string; email: string; password: string; role?: string }) {
    return request.post('/auth/register', data)
  },
  getMe() {
    return request.get('/auth/me')
  },
  createCompany(data: { name: string; industry?: string }) {
    return request.post('/auth/company', data)
  },
  joinCompany(data: { company_id: number }) {
    return request.post('/auth/company/join', data)
  },
}
