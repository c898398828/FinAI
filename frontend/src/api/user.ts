import request from './request'

export const userApi = {
  getCompanyMembers() {
    return request.get('/users/company/members')
  },
  inviteCompanyMember(data: { username?: string; email?: string; role?: string }) {
    return request.post('/users/company/members/invite', data)
  },
  removeCompanyMember(userId: number) {
    return request.delete(`/users/company/members/${userId}`)
  },
  setCompanyMemberRole(userId: number, role: 'admin' | 'accountant' | 'viewer') {
    return request.put(`/users/company/members/${userId}/role`, { role })
  },
  transferSuperAdmin(target_user_id: number) {
    return request.post('/users/company/super-admin/transfer', { target_user_id })
  },
  dissolveCompany() {
    return request.delete('/users/company')
  },
}
