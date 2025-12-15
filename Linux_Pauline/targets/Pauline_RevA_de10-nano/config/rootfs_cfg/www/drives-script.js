/*
 * drives-script.js
 * Gestion du fichier drives.script : génération, parsing, upload, sauvegarde
 * Réutilisable pour d'autres pages si nécessaire
 */

// Fonction pour initialiser le drag & drop
function initDrivesScriptDragDrop() {
	var dropZone = document.getElementById('drop-zone-drives-script');
	var fileInput = document.getElementById('file-upload-drives-script');
	
	if (!dropZone || !fileInput) return;
	
	// Empêcher le comportement par défaut du navigateur
	['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
		dropZone.addEventListener(eventName, preventDefaults, false);
		document.body.addEventListener(eventName, preventDefaults, false);
	});
	
	function preventDefaults(e) {
		e.preventDefault();
		e.stopPropagation();
	}
	
	// Gérer les événements de survol (utilise la classe CSS drop-over)
	['dragenter', 'dragover'].forEach(eventName => {
		dropZone.addEventListener(eventName, function() {
			dropZone.classList.add('drag-over');
		}, false);
	});
	
	['dragleave', 'drop'].forEach(eventName => {
		dropZone.addEventListener(eventName, function() {
			dropZone.classList.remove('drag-over');
		}, false);
	});
	
	// Gérer le drop
	dropZone.addEventListener('drop', function(e) {
		var dt = e.dataTransfer;
		var files = dt.files;
		handleDrivesScriptFileUpload(files);
	}, false);
	
	// Permettre de cliquer sur la zone de drop pour ouvrir le sélecteur de fichier
	dropZone.addEventListener('click', function() {
		fileInput.click();
	});
}

// Fonction pour gérer l'upload de fichier
function handleDrivesScriptFileUpload(files) {
	if (!files || files.length === 0) {
		return;
	}
	
	var file = files[0];
	var statusEl = document.getElementById('file-upload-status');
	
	// Vérifier que c'est un fichier texte
	if (!file.name.endsWith('.script') && !file.type.startsWith('text/')) {
		if (statusEl) {
			statusEl.textContent = '❌ Error: File must be a .script or text file';
			statusEl.style.color = 'red';
		}
		return;
	}
	
	if (statusEl) {
		statusEl.textContent = '📖 Reading file...';
		statusEl.style.color = 'blue';
	}
	
	var reader = new FileReader();
	reader.onload = function(e) {
		var content = e.target.result;
		var contentEl = document.getElementById('drives-script-content');
		if (contentEl) {
			contentEl.value = content;
		}
		
		// Analyser le fichier et mettre à jour la console si la fonction existe
		if (typeof parseDrivesScript === 'function') {
			parseDrivesScript(content);
		}
		
		// Basculer vers l'onglet console pour voir les valeurs mises à jour
		if (typeof switchTab === 'function') {
			switchTab('console');
		}
		
		if (statusEl) {
			statusEl.textContent = '✅ File loaded and analyzed: ' + file.name + ' (' + file.size + ' bytes)';
			statusEl.style.color = 'green';
		}
	};
	reader.onerror = function() {
		if (statusEl) {
			statusEl.textContent = '❌ Error reading file';
			statusEl.style.color = 'red';
		}
	};
	reader.readAsText(file);
}

// Fonction pour charger le drives.script depuis le serveur
function loadDrivesScript() {
	if (!confirm('Are you sure you want to load the drives.script file from the server?\n\nThis will overwrite the current configuration settings in the console.')) {
		return;
	}
	
	// Attendre que la connexion soit établie avant d'envoyer
	if (typeof waitForWebSocketConnection === 'function') {
		waitForWebSocketConnection(function() {
			// Afficher un message de chargement
			var contentEl = document.getElementById("drives-script-content");
			if (contentEl) {
				contentEl.value = "# Loading...\n";
			}
			window.drivesScriptBuffer = '';
			window.drivesScriptLoading = true;
			
			// Commande pour lire le fichier drives.script
			var txt = "system cat /home/pauline/Settings/drives.script 2>&1\n";
			if (typeof ws !== 'undefined' && ws) {
				ws.send(txt);
			}
			var logEl = document.getElementById("taLog");
			if (logEl) {
				logEl.value += ("Send: " + txt + "\n");
			}
			
			// Arrêter le mode de chargement après un délai raisonnable (5 secondes)
			setTimeout(function() {
				if (window.drivesScriptLoading) {
					window.drivesScriptLoading = false;
					if (window.drivesScriptBuffer && window.drivesScriptBuffer.trim() !== '') {
						var content = window.drivesScriptBuffer;
						if (contentEl) {
							contentEl.value = content;
						}
						
						// Analyser le fichier et mettre à jour la console
						if (typeof parseDrivesScript === 'function') {
							parseDrivesScript(content);
						}
					} else {
						if (contentEl) {
							contentEl.value = "# Error: Unable to load drives.script file\n# Check the console for more details.";
						}
					}
				}
			}, 5000);
		}, 50);
	}
}

// Fonction pour sauvegarder le drives.script sur le serveur
function saveDrivesScript() {
	// Si on est dans l'onglet console, utiliser le contenu généré
	var consoleTab = document.getElementById('console-tab');
	var content;
	
	if (consoleTab && consoleTab.style.display !== 'none') {
		// Utiliser le contenu généré depuis la console
		var previewEl = document.getElementById("drives-script-preview");
		content = previewEl ? previewEl.value : '';
	} else {
		// Utiliser le contenu du textarea
		var contentEl = document.getElementById("drives-script-content");
		content = contentEl ? contentEl.value : '';
	}
	
	if (!content || content.trim() === '') {
		alert('Content is empty. Please enter the drives.script file content or configure the console.');
		return;
	}
	
	if (!confirm('Are you sure you want to save this content to /home/pauline/Settings/drives.script?\n\nThis action will overwrite the existing file.')) {
		return;
	}
	
	// Attendre que la connexion soit établie avant d'envoyer
	if (typeof waitForWebSocketConnection === 'function') {
		waitForWebSocketConnection(function() {
			// Sauvegarder via une commande système
			var txt = "system bash -c 'cat > /tmp/drives_script_temp.txt << \"EOF\"\n" + 
			          content.replace(/\$/g, '\\$').replace(/`/g, '\\`') + 
			          "\nEOF\ncp /tmp/drives_script_temp.txt /home/pauline/Settings/drives.script && echo \"File saved successfully\" || echo \"Error saving file\"' 2>&1\n";
			
			if (typeof ws !== 'undefined' && ws) {
				ws.send(txt);
			}
			var logEl = document.getElementById("taLog");
			if (logEl) {
				logEl.value += ("Send: Saving drives.script file\n");
			}
			
			alert('Save command sent. Check the console to confirm the save.');
		}, 50);
	}
}

// Fonction pour recharger la configuration
function reloadConfig() {
	if (!confirm('Are you sure you want to reload the configuration?\n\nThis will apply the current drives.script settings and reset the FPGA.\n\nThis action will overwrite the current active configuration.')) {
		return;
	}
	
	// Attendre que la connexion soit établie avant d'envoyer
	if (typeof waitForWebSocketConnection === 'function') {
		waitForWebSocketConnection(function() {
			var txt = "reload_config\n";
			if (typeof ws !== 'undefined' && ws) {
				ws.send(txt);
			}
			var logEl = document.getElementById("taLog");
			if (logEl) {
				logEl.value += ("Send: " + txt + "\n");
			}
		}, 50);
	}
}

// Fonction pour générer le contenu du drives.script
function generateDrivesScriptContent() {
	var lines = [];
	lines.push('#');
	lines.push('# Pauline drives configuration file');
	lines.push('#');
	lines.push('');
	lines.push('# -----------------------------------------------------------------------------');
	lines.push('#');
	lines.push('# To setup a drive you need to set its "Motor on" and "Select" lines.');
	lines.push('#');
	lines.push('# You can use up to 4 Shugart drives or up to 2 PC drives.');
	lines.push('# See the notes if you want to mixup Shugart and PC drives on the same bus.');
	lines.push('#');
	lines.push('# --- Shugart Floppy disk drives ---');
	lines.push('#');
	lines.push('# Shugart drives can have 4 differents select lines and 1 motor line.');
	lines.push('# The motor-on is common to all floppy drive on the same bus.');
	lines.push('#');
	lines.push('# Possible Shugart select lines (one per drive !) :');
	lines.push('# DRIVES_PORT_DS0, DRIVES_PORT_DS1 , DRIVES_PORT_DS2 , DRIVES_PORT_DS3');
	lines.push('#');
	lines.push('# --- PC Floppy disk drives ---');
	lines.push('#');
	lines.push('# PC drives can have 2 differents settings :');
	lines.push('# - Drive "A:"');
	lines.push('# Select Line : DRIVES_PORT_DRVSA');
	lines.push('# Motor  Line : DRIVES_PORT_MOTEA');
	lines.push('#');
	lines.push('# - Drive "B:"');
	lines.push('# Select Line : DRIVES_PORT_DRVSB');
	lines.push('# Motor  Line : DRIVES_PORT_MOTEB');
	lines.push('#');
	lines.push('# -----------------------------------------------------------------------------');
	lines.push('');
	lines.push('# Uncomment the following line to enable the Apple Disk II interface mode');
	lines.push('');
	lines.push('# "GENERIC_FLOPPY_INTERFACE"');
	lines.push('# "APPLE_MACINTOSH_FLOPPY_INTERFACE"');
	lines.push('# "APPLE_II_FLOPPY_INTERFACE"');
	lines.push('');
	
	var interfaceModeEl = document.getElementById('config-interface-mode');
	lines.push('set DRIVES_INTERFACE_MODE "' + (interfaceModeEl ? interfaceModeEl.value : 'GENERIC_FLOPPY_INTERFACE') + '"');
	lines.push('');
	lines.push('# set ENABLE_APPLE_MODE 1');
	lines.push('');
	lines.push('#');
	lines.push('# Macintosh drive GCR mode');
	lines.push('# 0 -> MFM disks, 1 GCR disks.');
	lines.push('# (Can be changed on the control web page)');
	lines.push('#');
	lines.push('');
	
	var macGcrEl = document.getElementById('config-mac-gcr-mode');
	lines.push('set MACINTOSH_GCR_MODE ' + (macGcrEl ? macGcrEl.value : '0'));
	lines.push('');
	lines.push('#');
	lines.push('# Uncomment the following line to disable the sound output.');
	lines.push('#');
	lines.push('');
	
	var soundEl = document.getElementById('config-sound-enabled');
	if (!soundEl || !soundEl.checked) {
		lines.push('set PAULINE_UI_SOUND 0');
	} else {
		lines.push('# set PAULINE_UI_SOUND 0');
	}
	lines.push('');
	lines.push('#');
	lines.push('# Additionnal drive spin up delay when the motor is turned on.');
	lines.push('# (in milli-seconds)');
	lines.push('#');
	lines.push('');
	
	var motorSpinupEl = document.getElementById('config-motor-spinup');
	lines.push('set DRIVE_MOTOR_SPINUP_DELAY ' + (motorSpinupEl ? motorSpinupEl.value : '1000'));
	lines.push('');
	lines.push('#');
	lines.push('# Delay to wait after the head load');
	lines.push('# (in milli-seconds)');
	lines.push('#');
	lines.push('');
	
	var headLoadEl = document.getElementById('config-head-load');
	lines.push('set DRIVE_HEAD_LOAD_DELAY ' + (headLoadEl ? headLoadEl.value : '250'));
	lines.push('');
	lines.push('#');
	lines.push('# Delay to wait after the head load');
	lines.push('# (in micro-seconds)');
	lines.push('# Typical minimum values :');
	lines.push('# 3"1/2 -> 2ms (2000)');
	lines.push('# 5"1/4 -> 12ms (12000)');
	lines.push('#');
	lines.push('');
	
	var headStepRateEl = document.getElementById('config-head-step-rate');
	lines.push('set DRIVE_HEAD_STEP_RATE ' + (headStepRateEl ? headStepRateEl.value : '24000'));
	lines.push('');
	
	var headSettlingEl = document.getElementById('config-head-settling');
	lines.push('set DRIVE_HEAD_SETTLING_TIME ' + (headSettlingEl ? headSettlingEl.value : '16000'));
	lines.push('');
	lines.push('#');
	lines.push('# Step signal width (Shugart drives).');
	lines.push('# (in micro-seconds)');
	lines.push('#');
	lines.push('');
	
	var stepWidthEl = document.getElementById('config-step-width');
	lines.push('set DRIVE_STEP_SIGNAL_WIDTH ' + (stepWidthEl ? stepWidthEl.value : '8'));
	lines.push('');
	lines.push('#');
	lines.push('# Apple Phases signal output width');
	lines.push('#');
	lines.push('# DRIVE_STEP_PHASES_STOP_WIDTH timing is used');
	lines.push('# at the last step');
	lines.push('#');
	lines.push('# I recommend to increase the DRIVE_HEAD_SETTLING_TIME value');
	lines.push('# at least to the DRIVE_STEP_PHASES_STOP_WIDTH or more');
	lines.push('# to be sure that the head is well stabilized.');
	lines.push('#');
	lines.push('');
	
	var phasesWidthEl = document.getElementById('config-phases-width');
	lines.push('set DRIVE_STEP_PHASES_WIDTH ' + (phasesWidthEl ? phasesWidthEl.value : '14000'));
	
	var phasesStopWidthEl = document.getElementById('config-phases-stop-width');
	lines.push('set DRIVE_STEP_PHASES_STOP_WIDTH ' + (phasesStopWidthEl ? phasesStopWidthEl.value : '36000'));
	lines.push('');
	lines.push('#');
	lines.push('# Set the index signal polarity');
	lines.push('# 0 -> Active low (default)');
	lines.push('# 1 -> Active high');
	lines.push('# Usefull if you use a custom index sensor');
	lines.push('#');
	lines.push('');
	
	var indexPolarityEl = document.getElementById('config-index-polarity');
	lines.push('set DRIVE_INDEX_SIGNAL_POLARITY ' + (indexPolarityEl ? indexPolarityEl.value : '0'));
	lines.push('');
	lines.push('');
	
	// Générer les configurations pour chaque drive
	for (var driveNum = 0; driveNum <= 3; driveNum++) {
		lines.push('#');
		lines.push('# Drive ' + driveNum + ' settings');
		lines.push('#');
		lines.push('');
		
		var enabledEl = document.getElementById('config-drive-' + driveNum + '-enabled');
		var isEnabled = enabledEl ? enabledEl.checked : true;
		
		if (isEnabled) {
			var descEl = document.getElementById('config-drive-' + driveNum + '-desc');
			var selectEl = document.getElementById('config-drive-' + driveNum + '-select');
			var motorEl = document.getElementById('config-drive-' + driveNum + '-motor');
			var maxStepsEl = document.getElementById('config-drive-' + driveNum + '-max-steps');
			
			lines.push('set DRIVE_' + driveNum + '_DESCRIPTION "' + (descEl ? descEl.value : '') + '"');
			lines.push('set DRIVE_' + driveNum + '_SELECT_LINE ' + (selectEl ? selectEl.value : 'DRIVES_PORT_DS' + driveNum));
			lines.push('set DRIVE_' + driveNum + '_MOTOR_LINE  ' + (motorEl ? motorEl.value : 'DRIVES_PORT_MOTON'));
			lines.push('set DRIVE_' + driveNum + '_MAX_STEPS   ' + (maxStepsEl ? maxStepsEl.value : '82'));
			
			// Drive 1 a une option HEADLOAD_LINE spéciale
			if (driveNum === 1) {
				var headloadEnabledEl = document.getElementById('config-drive-1-headload-enabled');
				if (headloadEnabledEl && headloadEnabledEl.checked) {
					var headloadEl = document.getElementById('config-drive-1-headload');
					lines.push('set DRIVE_1_HEADLOAD_LINE ' + (headloadEl ? headloadEl.value : 'DRIVES_PORT_PIN04_OUT'));
				}
			}
			
			// X68000 option
			var x68000EnabledEl = document.getElementById('config-drive-' + driveNum + '-x68000-enabled');
			if (x68000EnabledEl && x68000EnabledEl.checked) {
				lines.push('');
				var x68000El = document.getElementById('config-drive-' + driveNum + '-x68000');
				lines.push('set DRIVE_' + driveNum + '_X68000_OPTION_SELECT_LINE ' + (x68000El ? x68000El.value : 'DRIVES_PORT_X68000_OPTIONSEL' + driveNum + '_OUT'));
			} else {
				lines.push('');
				lines.push('#set DRIVE_' + driveNum + '_X68000_OPTION_SELECT_LINE DRIVES_PORT_X68000_OPTIONSEL' + driveNum + '_OUT');
			}
		} else {
			var descEl = document.getElementById('config-drive-' + driveNum + '-desc');
			var selectEl = document.getElementById('config-drive-' + driveNum + '-select');
			var motorEl = document.getElementById('config-drive-' + driveNum + '-motor');
			var maxStepsEl = document.getElementById('config-drive-' + driveNum + '-max-steps');
			
			lines.push('# set DRIVE_' + driveNum + '_DESCRIPTION "' + (descEl ? descEl.value : '') + '"');
			lines.push('# set DRIVE_' + driveNum + '_SELECT_LINE ' + (selectEl ? selectEl.value : 'DRIVES_PORT_DS' + driveNum));
			lines.push('# set DRIVE_' + driveNum + '_MOTOR_LINE  ' + (motorEl ? motorEl.value : 'DRIVES_PORT_MOTON'));
			lines.push('# set DRIVE_' + driveNum + '_MAX_STEPS   ' + (maxStepsEl ? maxStepsEl.value : '82'));
		}
		lines.push('');
	}
	
	return lines.join('\n');
}

// Fonction pour mettre à jour le drives.script
function updateDrivesScript() {
	// Générer le contenu du fichier drives.script à partir des options
	var content = generateDrivesScriptContent();
	var previewEl = document.getElementById('drives-script-preview');
	if (previewEl) {
		previewEl.value = content;
	}
	var contentEl = document.getElementById('drives-script-content');
	if (contentEl) {
		contentEl.value = content;
	}
}

// Fonction pour générer depuis la console
function generateDrivesScriptFromConsole() {
	updateDrivesScript();
	alert('drives.script generated from console configuration. You can now save it to the server.');
}

// Fonction pour parser le drives.script et mettre à jour l'interface
function parseDrivesScript(content) {
	// Analyser le contenu du fichier drives.script et mettre à jour l'interface
	var lines = content.split('\n');
	
	// Détecter quels drives sont présents (non commentés)
	var drivesPresent = {0: false, 1: false, 2: false, 3: false};
	
	for (var i = 0; i < lines.length; i++) {
		var line = lines[i].trim();
		
		// Vérifier si un drive est présent (non commenté)
		var driveMatch = line.match(/^set\s+DRIVE_(\d)_DESCRIPTION/);
		if (driveMatch) {
			var driveNum = parseInt(driveMatch[1]);
			drivesPresent[driveNum] = true;
		}
		
		// Ignorer les commentaires et lignes vides
		if (line.startsWith('#') || line === '') {
			continue;
		}
		
		// Parser les commandes set
		var match = line.match(/^set\s+(\w+)\s+(.+)$/);
		if (match) {
			var key = match[1];
			var value = match[2].replace(/^["']|["']$/g, ''); // Enlever les guillemets
			
			// Mettre à jour les champs correspondants
			var el = document.getElementById('config-' + key.toLowerCase().replace(/_/g, '-'));
			if (el) {
				if (el.type === 'checkbox') {
					el.checked = (value !== '0' && value !== 'false');
				} else {
					el.value = value;
				}
			}
			
			// Gestion spéciale pour les champs avec des noms différents
			switch(key) {
				case 'DRIVES_INTERFACE_MODE':
					el = document.getElementById('config-interface-mode');
					if (el) el.value = value;
					break;
				case 'MACINTOSH_GCR_MODE':
					el = document.getElementById('config-mac-gcr-mode');
					if (el) el.value = value;
					break;
				case 'PAULINE_UI_SOUND':
					el = document.getElementById('config-sound-enabled');
					if (el) el.checked = (value !== '0');
					break;
				case 'DRIVE_MOTOR_SPINUP_DELAY':
					el = document.getElementById('config-motor-spinup');
					if (el) el.value = value;
					break;
				case 'DRIVE_HEAD_LOAD_DELAY':
					el = document.getElementById('config-head-load');
					if (el) el.value = value;
					break;
				case 'DRIVE_HEAD_STEP_RATE':
					el = document.getElementById('config-head-step-rate');
					if (el) el.value = value;
					break;
				case 'DRIVE_HEAD_SETTLING_TIME':
					el = document.getElementById('config-head-settling');
					if (el) el.value = value;
					break;
				case 'DRIVE_STEP_SIGNAL_WIDTH':
					el = document.getElementById('config-step-width');
					if (el) el.value = value;
					break;
				case 'DRIVE_STEP_PHASES_WIDTH':
					el = document.getElementById('config-phases-width');
					if (el) el.value = value;
					break;
				case 'DRIVE_STEP_PHASES_STOP_WIDTH':
					el = document.getElementById('config-phases-stop-width');
					if (el) el.value = value;
					break;
				case 'DRIVE_INDEX_SIGNAL_POLARITY':
					el = document.getElementById('config-index-polarity');
					if (el) el.value = value;
					break;
			}
			
			// Gestion des drives
			var driveMatch = key.match(/^DRIVE_(\d)_(.+)$/);
			if (driveMatch) {
				var driveNum = parseInt(driveMatch[1]);
				var field = driveMatch[2];
				
				switch(field) {
					case 'DESCRIPTION':
						el = document.getElementById('config-drive-' + driveNum + '-desc');
						if (el) el.value = value;
						break;
					case 'SELECT_LINE':
						el = document.getElementById('config-drive-' + driveNum + '-select');
						if (el) el.value = value;
						break;
					case 'MOTOR_LINE':
						el = document.getElementById('config-drive-' + driveNum + '-motor');
						if (el) el.value = value;
						break;
					case 'MAX_STEPS':
						el = document.getElementById('config-drive-' + driveNum + '-max-steps');
						if (el) el.value = value;
						break;
					case 'HEADLOAD_LINE':
						var checkbox = document.getElementById('config-drive-1-headload-enabled');
						var select = document.getElementById('config-drive-1-headload');
						if (checkbox) checkbox.checked = true;
						if (select) select.value = value;
						var optionsEl = document.getElementById('drive-1-headload-options');
						if (optionsEl) optionsEl.style.display = 'block';
						break;
					case 'X68000_OPTION_SELECT_LINE':
						var checkbox = document.getElementById('config-drive-' + driveNum + '-x68000-enabled');
						var select = document.getElementById('config-drive-' + driveNum + '-x68000');
						if (checkbox) checkbox.checked = true;
						if (select) select.value = value;
						var optionsEl = document.getElementById('drive-' + driveNum + '-x68000-options');
						if (optionsEl) optionsEl.style.display = 'block';
						break;
				}
			}
		}
	}
	
	// Désactiver les drives qui ne sont pas présents dans le fichier
	for (var driveNum = 0; driveNum <= 3; driveNum++) {
		var checkbox = document.getElementById('config-drive-' + driveNum + '-enabled');
		if (checkbox && typeof toggleDrive === 'function') {
			if (drivesPresent[driveNum]) {
				checkbox.checked = true;
				toggleDrive(driveNum, true);
			} else {
				checkbox.checked = false;
				toggleDrive(driveNum, false);
			}
		}
	}
	
	// Mettre à jour l'aperçu après l'analyse
	updateDrivesScript();
}

