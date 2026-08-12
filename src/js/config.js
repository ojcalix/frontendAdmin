// js/config.js
const API_URL =
    window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:3000'
        : 'https://backendadmin-production-b6fc.up.railway.app';