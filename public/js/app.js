// JavaScript pour le Gestionnaire de Dépenses

document.addEventListener('DOMContentLoaded', function() {
    // Initialisation
    initializeApp();
    
    // Event listeners
    setupEventListeners();
    
    // Auto-refresh des données toutes les 30 secondes (optionnel)
    // setInterval(refreshStats, 30000);
});

function initializeApp() {
    // Afficher un message de bienvenue dans la console
    console.log('🎯 Gestionnaire de Dépenses - Interface Web chargée');
    
    // Initialiser les tooltips Bootstrap
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Initialiser les popovers Bootstrap
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });
    
    // Formater automatiquement les montants
    formatCurrencyInputs();
    
    // Valider les formulaires
    setupFormValidation();
}

function setupEventListeners() {
    // Confirmation de suppression pour tous les boutons de suppression
    document.querySelectorAll('[onclick*="delete"]').forEach(button => {
        button.addEventListener('click', function(e) {
            if (!confirm('Êtes-vous sûr de vouloir supprimer cet élément ?')) {
                e.preventDefault();
                e.stopPropagation();
            }
        });
    });
    
    // Auto-save pour les formulaires (optionnel)
    setupAutoSave();
    
    // Recherche en temps réel
    setupLiveSearch();
    
    // Raccourcis clavier
    setupKeyboardShortcuts();
}

function formatCurrencyInputs() {
    const currencyInputs = document.querySelectorAll('input[type="number"][step="0.01"]');
    
    currencyInputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (this.value) {
                this.value = parseFloat(this.value).toFixed(2);
            }
        });
        
        input.addEventListener('input', function() {
            // Empêcher les valeurs négatives
            if (this.value < 0) {
                this.value = 0;
            }
        });
    });
}

function setupFormValidation() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        form.addEventListener('submit', function(e) {
            if (!form.checkValidity()) {
                e.preventDefault();
                e.stopPropagation();
                
                // Afficher les erreurs de validation
                showValidationErrors(form);
            } else {
                // Afficher un indicateur de chargement
                showLoadingState(form);
            }
            
            form.classList.add('was-validated');
        });
    });
}

function showValidationErrors(form) {
    const invalidInputs = form.querySelectorAll(':invalid');
    
    if (invalidInputs.length > 0) {
        const firstInvalid = invalidInputs[0];
        firstInvalid.focus();
        
        // Créer un message d'erreur personnalisé
        showAlert('Veuillez corriger les erreurs dans le formulaire.', 'warning');
    }
}

function showLoadingState(form) {
    const submitButton = form.querySelector('button[type="submit"]');
    
    if (submitButton) {
        const originalText = submitButton.innerHTML;
        submitButton.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Traitement...';
        submitButton.disabled = true;
        
        // Restaurer l'état original après 3 secondes (au cas où)
        setTimeout(() => {
            submitButton.innerHTML = originalText;
            submitButton.disabled = false;
        }, 3000);
    }
}

function setupAutoSave() {
    const autoSaveInputs = document.querySelectorAll('[data-autosave]');
    
    autoSaveInputs.forEach(input => {
        let timeout;
        
        input.addEventListener('input', function() {
            clearTimeout(timeout);
            
            timeout = setTimeout(() => {
                // Sauvegarder automatiquement (localStorage pour l'instant)
                const key = `autosave_${input.name || input.id}`;
                localStorage.setItem(key, input.value);
                
                // Afficher un indicateur de sauvegarde
                showAutoSaveIndicator(input);
            }, 1000);
        });
        
        // Restaurer les valeurs sauvegardées
        const key = `autosave_${input.name || input.id}`;
        const savedValue = localStorage.getItem(key);
        if (savedValue && !input.value) {
            input.value = savedValue;
        }
    });
}

function showAutoSaveIndicator(input) {
    // Créer un petit indicateur de sauvegarde
    const indicator = document.createElement('small');
    indicator.className = 'text-success';
    indicator.innerHTML = '<i class="fas fa-check"></i> Sauvegardé';
    
    // L'insérer après l'input
    input.parentNode.insertBefore(indicator, input.nextSibling);
    
    // Le supprimer après 2 secondes
    setTimeout(() => {
        if (indicator.parentNode) {
            indicator.parentNode.removeChild(indicator);
        }
    }, 2000);
}

function setupLiveSearch() {
    const searchInputs = document.querySelectorAll('[data-live-search]');
    
    searchInputs.forEach(input => {
        input.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();
            const targetSelector = this.dataset.liveSearch;
            const targets = document.querySelectorAll(targetSelector);
            
            targets.forEach(target => {
                const text = target.textContent.toLowerCase();
                const shouldShow = text.includes(searchTerm);
                
                target.style.display = shouldShow ? '' : 'none';
            });
        });
    });
}

function setupKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Ctrl/Cmd + N : Nouvelle dépense
        if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
            e.preventDefault();
            const amountInput = document.querySelector('input[name="amount"]');
            if (amountInput) {
                amountInput.focus();
            }
        }
        
        // Ctrl/Cmd + S : Sauvegarder (si dans un formulaire)
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            const activeForm = document.querySelector('form:focus-within');
            if (activeForm) {
                e.preventDefault();
                activeForm.submit();
            }
        }
        
        // Échap : Fermer les modales/dropdowns
        if (e.key === 'Escape') {
            const openDropdowns = document.querySelectorAll('.dropdown-menu.show');
            openDropdowns.forEach(dropdown => {
                bootstrap.Dropdown.getInstance(dropdown.previousElementSibling)?.hide();
            });
        }
    });
}

function showAlert(message, type = 'info', duration = 5000) {
    // Créer une alerte Bootstrap
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    alertDiv.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Supprimer automatiquement après la durée spécifiée
    setTimeout(() => {
        if (alertDiv.parentNode) {
            alertDiv.remove();
        }
    }, duration);
}

function refreshStats() {
    // Rafraîchir les statistiques via AJAX (optionnel)
    fetch('/api/stats')
        .then(response => response.json())
        .then(data => {
            updateStatsDisplay(data);
        })
        .catch(error => {
            console.error('Erreur lors du rafraîchissement des stats:', error);
        });
}

function updateStatsDisplay(stats) {
    // Mettre à jour l'affichage des statistiques
    const totalElement = document.querySelector('[data-stat="total"]');
    const countElement = document.querySelector('[data-stat="count"]');
    const averageElement = document.querySelector('[data-stat="average"]');
    
    if (totalElement) totalElement.textContent = `${stats.total_amount.toFixed(2)} €`;
    if (countElement) countElement.textContent = stats.total_count;
    if (averageElement) averageElement.textContent = `${stats.average_expense.toFixed(2)} €`;
}

// Fonctions utilitaires
function formatCurrency(amount) {
    return new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR'
    }).format(amount);
}

function formatDate(dateString) {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(dateString));
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Fonctions globales pour les actions de suppression
window.deleteExpense = function(id) {
    if (confirm('Êtes-vous sûr de vouloir supprimer cette dépense ?')) {
        fetch(`/expenses/${id}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showAlert('Dépense supprimée avec succès', 'success');
                setTimeout(() => location.reload(), 1000);
            } else {
                showAlert('Erreur lors de la suppression', 'danger');
            }
        })
        .catch(error => {
            console.error('Erreur:', error);
            showAlert('Erreur lors de la suppression', 'danger');
        });
    }
};

window.deleteCategory = function(categoryName) {
    if (confirm(`Êtes-vous sûr de vouloir supprimer la catégorie "${categoryName}" ?\n\nToutes les dépenses de cette catégorie seront déplacées vers "Autres".`)) {
        fetch(`/categories/${encodeURIComponent(categoryName)}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showAlert('Catégorie supprimée avec succès', 'success');
                setTimeout(() => location.reload(), 1000);
            } else {
                showAlert('Erreur lors de la suppression de la catégorie', 'danger');
            }
        })
        .catch(error => {
            console.error('Erreur:', error);
            showAlert('Erreur lors de la suppression de la catégorie', 'danger');
        });
    }
};