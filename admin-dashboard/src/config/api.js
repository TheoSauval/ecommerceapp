import axios from 'axios';

const API_URL = 'http://localhost:4000/api';

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  console.log('🔑 Token dans localStorage:', token ? 'Présent' : 'Manquant');
  
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
    console.log('📤 Token ajouté aux headers:', config.headers.Authorization ? 'Oui' : 'Non');
  } else {
    console.log('❌ Aucun token trouvé dans localStorage');
  }
  
  // Ajouter un header pour identifier le dashboard
  config.headers['x-client-type'] = 'dashboard';
  
  console.log('🌐 Requête vers:', config.method?.toUpperCase(), config.url);
  return config;
});

// Intercepteur pour les réponses
api.interceptors.response.use(
  (response) => {
    console.log('✅ Réponse reçue:', response.status, response.config.url);
    return response;
  },
  (error) => {
    console.log('❌ Erreur de réponse:', error.response?.status, error.config?.url);
    console.log('❌ Détails de l\'erreur:', error.response?.data);
    if (error.response?.status === 401) {
      // Token expiré ou invalide
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api; 