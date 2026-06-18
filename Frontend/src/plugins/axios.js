import axios from 'axios'

axios.defaults.baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
axios.defaults.withCredentials = true  // ← send cookies automatically

// remove the Authorization header interceptor, cookies are sent automatically

axios.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default axios