import axios from'axios';
export const api=axios.create({baseURL:import.meta.env.VITE_API_URL||'http://localhost:8080/api'});
api.interceptors.request.use(c=>{const t=sessionStorage.getItem('ft_access');if(t)c.headers.Authorization=`Bearer ${t}`;return c;});
