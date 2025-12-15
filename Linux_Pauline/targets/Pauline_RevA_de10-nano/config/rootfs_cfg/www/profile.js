/*
 * Gestion des profils utilisateurs et thèmes
 */

// Constantes
const PROFILE_STANDARD = 'standard';
const PROFILE_ARCHIVISTE = 'archiviste';
const THEME_LIGHT = 'light';
const THEME_DARK = 'dark';

// Fonctions de gestion des profils
function getCurrentProfile() {
    return localStorage.getItem('pauline_profile') || PROFILE_STANDARD;
}

function setProfile(profile) {
    if (profile === PROFILE_STANDARD || profile === PROFILE_ARCHIVISTE) {
        localStorage.setItem('pauline_profile', profile);
        updateProfileIndicator();
        // Recharger la page si on est sur dump.html pour appliquer les changements
        if (window.location.pathname.includes('dump.html')) {
            window.location.reload();
        }
        return true;
    }
    return false;
}

function updateProfileIndicator() {
    const indicator = document.getElementById('profile-indicator');
    if (indicator) {
        const profile = getCurrentProfile();
        indicator.textContent = 'Profil: ' + (profile === PROFILE_ARCHIVISTE ? 'Archiviste' : 'Standard');
        indicator.className = 'profile-indicator ' + profile;
    }
}

// Fonctions de gestion du thème
function getCurrentTheme() {
    return localStorage.getItem('pauline_theme') || THEME_LIGHT;
}

function setTheme(theme) {
    if (theme === THEME_LIGHT || theme === THEME_DARK) {
        localStorage.setItem('pauline_theme', theme);
        applyTheme();
        return true;
    }
    return false;
}

function applyTheme() {
    const theme = getCurrentTheme();
    document.body.className = theme === THEME_DARK ? 'theme-dark' : 'theme-light';
    const themeLink = document.getElementById('theme-stylesheet');
    if (themeLink) {
        themeLink.disabled = theme === THEME_LIGHT;
    }
}

// Initialisation au chargement de la page
document.addEventListener('DOMContentLoaded', function() {
    applyTheme();
    updateProfileIndicator();
});

