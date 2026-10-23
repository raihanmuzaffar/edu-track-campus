import axios from 'axios';

// Karena Nginx kita berjalan di port 80 (http://localhost/api)
const api = axios.create({
  baseURL: 'http://localhost/api/v1', 
});

// Ini untuk menyisipkan Token JWT secara otomatis jika user sudah login
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;