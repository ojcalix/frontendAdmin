// ========================
// Helpers de autenticación
// ========================
function getCurrentUserId() {
    return localStorage.getItem('user_id');
}

function getCurrentUsername() {
    return localStorage.getItem('username');
}

function getCurrentRole() {
    return localStorage.getItem('role');
}

// Verifica que haya sesión activa; si no, redirige al login
function requireAuth() {
    const token = localStorage.getItem('token');
    const userId = localStorage.getItem('user_id');

    if (!token || !userId) {
        window.location.href = 'login.html';
    }
}

// Cierra sesión y limpia todo
function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user_id');
    localStorage.removeItem('username');
    localStorage.removeItem('role');
    window.location.href = 'login.html';
}