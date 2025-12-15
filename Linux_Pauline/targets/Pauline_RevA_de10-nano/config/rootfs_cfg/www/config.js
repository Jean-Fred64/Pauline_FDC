/*
 * config.js
 * Fonctions spécifiques à la page config.html
 * Gestion de l'interface, onglets, sections, etc.
 */

// Fonction d'initialisation de la page config
function initConfigPage() {
	// Initialiser les sélecteurs avec les valeurs actuelles
	if (typeof getCurrentProfile === 'function' && typeof getCurrentTheme === 'function') {
		const currentProfile = getCurrentProfile();
		const currentTheme = getCurrentTheme();
		
		var profileSelect = document.getElementById('profile-select');
		var themeSelect = document.getElementById('theme-select');
		if (profileSelect) profileSelect.value = currentProfile;
		if (themeSelect) themeSelect.value = currentTheme;
		
		if (typeof updateProfileIndicator === 'function') {
			updateProfileIndicator();
		}
	}
	
	// Afficher l'adresse IP de la DE10
	updateDE10IPAddress();
	
	// Initialiser le drag & drop pour drives.script
	if (typeof initDrivesScriptDragDrop === 'function') {
		initDrivesScriptDragDrop();
	}
	
	// Initialiser les gestionnaires d'événements pour les options conditionnelles
	setupConditionalOptions();
	
	// Ouvrir toutes les sections par défaut
	var sections = ['interface-mode', 'mac-gcr', 'sound', 'timing', 'apple-phases', 'index', 'drive-0', 'drive-1', 'drive-2', 'drive-3'];
	sections.forEach(function(sectionId) {
		var content = document.getElementById(sectionId + '-content');
		var arrow = document.getElementById(sectionId + '-arrow');
		if (content && arrow) {
			content.style.display = 'block';
			arrow.textContent = '▼';
		}
	});
	
	// Générer un aperçu initial
	if (typeof updateDrivesScript === 'function') {
		updateDrivesScript();
	}
	
	// Charger le fichier drives.script au chargement
	// Attendre que la connexion soit établie avant de charger
	if (typeof waitForWebSocketConnection === 'function' && typeof loadDrivesScript === 'function') {
		waitForWebSocketConnection(function() {
			loadDrivesScript();
		});
	}
}

// Fonction pour configurer les options conditionnelles
function setupConditionalOptions() {
	// Drive 0 X68000
	var drive0X68000 = document.getElementById('config-drive-0-x68000-enabled');
	if (drive0X68000) {
		drive0X68000.addEventListener('change', function() {
			var optionsEl = document.getElementById('drive-0-x68000-options');
			if (optionsEl) {
				optionsEl.style.display = this.checked ? 'block' : 'none';
			}
			if (typeof updateDrivesScript === 'function') {
				updateDrivesScript();
			}
		});
	}
	
	// Drive 1 Headload
	var drive1Headload = document.getElementById('config-drive-1-headload-enabled');
	if (drive1Headload) {
		drive1Headload.addEventListener('change', function() {
			var optionsEl = document.getElementById('drive-1-headload-options');
			if (optionsEl) {
				optionsEl.style.display = this.checked ? 'block' : 'none';
			}
			if (typeof updateDrivesScript === 'function') {
				updateDrivesScript();
			}
		});
	}
	
	// Drive 1 X68000
	var drive1X68000 = document.getElementById('config-drive-1-x68000-enabled');
	if (drive1X68000) {
		drive1X68000.addEventListener('change', function() {
			var optionsEl = document.getElementById('drive-1-x68000-options');
			if (optionsEl) {
				optionsEl.style.display = this.checked ? 'block' : 'none';
			}
			if (typeof updateDrivesScript === 'function') {
				updateDrivesScript();
			}
		});
	}
	
	// Drive 2 X68000
	var drive2X68000 = document.getElementById('config-drive-2-x68000-enabled');
	if (drive2X68000) {
		drive2X68000.addEventListener('change', function() {
			var optionsEl = document.getElementById('drive-2-x68000-options');
			if (optionsEl) {
				optionsEl.style.display = this.checked ? 'block' : 'none';
			}
			if (typeof updateDrivesScript === 'function') {
				updateDrivesScript();
			}
		});
	}
	
	// Drive 3 X68000
	var drive3X68000 = document.getElementById('config-drive-3-x68000-enabled');
	if (drive3X68000) {
		drive3X68000.addEventListener('change', function() {
			var optionsEl = document.getElementById('drive-3-x68000-options');
			if (optionsEl) {
				optionsEl.style.display = this.checked ? 'block' : 'none';
			}
			if (typeof updateDrivesScript === 'function') {
				updateDrivesScript();
			}
		});
	}
}

// Fonction pour mettre à jour l'adresse IP de la DE10
function updateDE10IPAddress() {
	var ip = location.hostname || location.host.split(':')[0];
	var ipEl = document.getElementById('de10-ip-address');
	var sambaIpEl = document.getElementById('samba-ip');
	var sambaIpSmbEl = document.getElementById('samba-ip-smb');
	
	if (ipEl) ipEl.textContent = ip;
	if (sambaIpEl) sambaIpEl.textContent = ip;
	if (sambaIpSmbEl) sambaIpSmbEl.textContent = ip;
}

// Fonction pour copier le chemin Samba Windows
function copySambaPath() {
	var ip = location.hostname || location.host.split(':')[0];
	var sambaPath = '\\\\' + ip + '\\pauline\\Settings';
	copyToClipboard(sambaPath, 'btCopySambaPath', '#4CAF50', '#45a049');
}

// Fonction pour copier le chemin Samba Linux/macOS
function copySambaPathSMB() {
	var ip = location.hostname || location.host.split(':')[0];
	var sambaPathSMB = 'smb://' + ip + '/pauline/Settings';
	copyToClipboard(sambaPathSMB, 'btCopySambaPathSMB', '#2196F3', '#1976D2');
}

// Fonction générique pour copier dans le presse-papier
function copyToClipboard(text, buttonId, normalColor, hoverColor) {
	// Utiliser l'API Clipboard moderne si disponible
	if (navigator.clipboard && navigator.clipboard.writeText) {
		navigator.clipboard.writeText(text).then(function() {
			// Feedback visuel temporaire
			var btn = document.getElementById(buttonId);
			if (btn) {
				var originalText = btn.textContent;
				btn.textContent = '✓ Copied!';
				btn.style.backgroundColor = hoverColor;
				setTimeout(function() {
					btn.textContent = originalText;
					btn.style.backgroundColor = normalColor;
				}, 2000);
			}
		}).catch(function(err) {
			console.error('Failed to copy: ', err);
			alert('Failed to copy to clipboard. Please copy manually: ' + text);
		});
	} else {
		// Fallback pour les navigateurs plus anciens
		var textArea = document.createElement('textarea');
		textArea.value = text;
		textArea.style.position = 'fixed';
		textArea.style.left = '-999999px';
		textArea.style.top = '-999999px';
		document.body.appendChild(textArea);
		textArea.focus();
		textArea.select();
		try {
			var successful = document.execCommand('copy');
			if (successful) {
				var btn = document.getElementById(buttonId);
				if (btn) {
					var originalText = btn.textContent;
					btn.textContent = '✓ Copied!';
					btn.style.backgroundColor = hoverColor;
					setTimeout(function() {
						btn.textContent = originalText;
						btn.style.backgroundColor = normalColor;
					}, 2000);
				}
			} else {
				alert('Failed to copy to clipboard. Please copy manually: ' + text);
			}
		} catch (err) {
			console.error('Fallback copy failed: ', err);
			alert('Failed to copy to clipboard. Please copy manually: ' + text);
		}
		document.body.removeChild(textArea);
	}
}

// Fonction pour attendre la connexion WebSocket
function waitForWebSocketConnection(callback, maxAttempts) {
	maxAttempts = maxAttempts || 50; // 5 secondes max (50 * 100ms)
	var attempts = 0;
	
	function checkConnection() {
		attempts++;
		
		if (typeof ws !== 'undefined' && ws && ws.readyState === WebSocket.OPEN) {
			callback();
		} else if (attempts < maxAttempts) {
			setTimeout(checkConnection, 100);
		} else {
			console.warn('WebSocket connection timeout after ' + attempts + ' attempts');
		}
	}
	checkConnection();
}

// Fonction pour changer le profil
function changeProfile(profile) {
	if (typeof setProfile === 'function') {
		if (setProfile(profile)) {
			if (typeof updateProfileIndicator === 'function') {
				updateProfileIndicator();
			}
			const inlineIndicator = document.getElementById('profile-indicator-inline');
			if (inlineIndicator) {
				inlineIndicator.textContent = 'Profile: ' + (profile === 'archiviste' ? 'Archivist' : 'Standard');
				inlineIndicator.className = 'profile-indicator ' + profile;
			}
		}
	}
}

// Fonction pour changer le thème
function changeTheme(theme) {
	if (typeof setTheme === 'function') {
		setTheme(theme);
	}
}

// Fonction pour basculer entre les onglets
function switchTab(tab) {
	var consoleTab = document.getElementById('console-tab');
	var importTab = document.getElementById('import-tab');
	var tabConsole = document.getElementById('tab-console');
	var tabImport = document.getElementById('tab-import');
	
	if (tab === 'console') {
		if (consoleTab) consoleTab.style.display = 'block';
		if (importTab) importTab.style.display = 'none';
		if (tabConsole) tabConsole.classList.add('active');
		if (tabImport) tabImport.classList.remove('active');
	} else {
		if (consoleTab) consoleTab.style.display = 'none';
		if (importTab) importTab.style.display = 'block';
		if (tabConsole) tabConsole.classList.remove('active');
		if (tabImport) tabImport.classList.add('active');
	}
}

// Fonction pour basculer l'affichage d'une section
function toggleSection(sectionId) {
	var content = document.getElementById(sectionId + '-content');
	var arrow = document.getElementById(sectionId + '-arrow');
	if (content && arrow) {
		if (content.style.display === 'none') {
			content.style.display = 'block';
			arrow.textContent = '▼';
		} else {
			content.style.display = 'none';
			arrow.textContent = '▶';
		}
	}
}

// Fonction pour activer/désactiver un drive
function toggleDrive(driveNum, enabled) {
	var section = document.getElementById('drive-' + driveNum + '-section');
	var content = document.getElementById('drive-' + driveNum + '-content');
	
	if (!section || !content) return;
	
	if (enabled) {
		section.classList.remove('drive-disabled');
		// Activer tous les champs
		var inputs = content.querySelectorAll('input, select');
		inputs.forEach(function(input) {
			input.disabled = false;
		});
	} else {
		section.classList.add('drive-disabled');
		// Désactiver tous les champs
		var inputs = content.querySelectorAll('input, select');
		inputs.forEach(function(input) {
			input.disabled = true;
		});
	}
	
	if (typeof updateDrivesScript === 'function') {
		updateDrivesScript();
	}
}

