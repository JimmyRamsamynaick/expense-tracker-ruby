#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'optparse'
require 'date'

class ExpenseTracker
  DATA_FILE = 'expenses.json'
  
  def initialize
    @expenses = load_expenses
    @categories = load_categories
  end
  
  def run
    if ARGV.empty?
      show_interactive_menu
    else
      parse_command_line
    end
  end
  
  private
  
  def show_interactive_menu
    loop do
      puts "\n" + "="*50
      puts "💰 EXPENSE TRACKER RUBY"
      puts "="*50
      puts "1. Ajouter une dépense"
      puts "2. Voir toutes les dépenses"
      puts "3. Modifier une dépense"
      puts "4. Supprimer une dépense"
      puts "5. Voir les rapports"
      puts "6. Gérer les catégories"
      puts "7. Exporter les données"
      puts "8. Quitter"
      puts "="*50
      print "Choisissez une option (1-8): "
      
      choice = gets.chomp
      
      case choice
      when '1'
        add_expense_interactive
      when '2'
        list_expenses
      when '3'
        edit_expense_interactive
      when '4'
        delete_expense_interactive
      when '5'
        show_reports_menu
      when '6'
        manage_categories
      when '7'
        export_menu
      when '8'
        puts "👋 Au revoir !"
        break
      else
        puts "❌ Option invalide. Veuillez choisir entre 1 et 8."
      end
    end
  end
  
  def parse_command_line
    # TODO: Implémenter le parsing des arguments de ligne de commande
    puts "🚧 Interface en ligne de commande en cours de développement..."
    puts "💡 Utilisez 'ruby expense_tracker.rb' pour l'interface interactive."
  end
  
  def add_expense_interactive
    puts "\n📝 AJOUTER UNE DÉPENSE"
    puts "-" * 30
    
    print "Montant (€): "
    amount = gets.chomp.to_f
    
    if amount <= 0
      puts "❌ Le montant doit être positif."
      return
    end
    
    puts "\nCatégories disponibles:"
    @categories.each_with_index { |cat, i| puts "#{i + 1}. #{cat}" }
    print "Choisissez une catégorie (numéro) ou tapez une nouvelle: "
    
    category_input = gets.chomp
    if category_input.match?(/^\d+$/)
      category_index = category_input.to_i - 1
      category = @categories[category_index] if category_index >= 0 && category_index < @categories.length
    end
    
    category ||= category_input
    add_category(category) unless @categories.include?(category)
    
    print "Description: "
    description = gets.chomp
    
    expense = {
      id: generate_id,
      amount: amount,
      category: category,
      description: description,
      date: Date.today.to_s,
      created_at: Time.now.to_s
    }
    
    @expenses << expense
    save_expenses
    
    puts "✅ Dépense ajoutée avec succès !"
    puts "💰 #{amount}€ - #{category} - #{description}"
  end
  
  def list_expenses
    puts "\n📊 TOUTES LES DÉPENSES"
    puts "-" * 50
    
    if @expenses.empty?
      puts "📭 Aucune dépense enregistrée."
      return
    end
    
    total = 0
    @expenses.sort_by { |e| e['date'] }.reverse.each_with_index do |expense, index|
      puts "#{index + 1}. #{expense['date']} | #{expense['amount']}€ | #{expense['category']} | #{expense['description']}"
      total += expense['amount']
    end
    
    puts "-" * 50
    puts "💰 Total: #{total}€"
  end
  
  def edit_expense_interactive
    puts "\n✏️ MODIFIER UNE DÉPENSE"
    puts "-" * 30
    
    if @expenses.empty?
      puts "📭 Aucune dépense à modifier."
      return
    end
    
    list_expenses
    print "\nNuméro de la dépense à modifier: "
    index = gets.chomp.to_i - 1
    
    if index < 0 || index >= @expenses.length
      puts "❌ Numéro invalide."
      return
    end
    
    expense = @expenses[index]
    puts "\nDépense actuelle: #{expense['amount']}€ - #{expense['category']} - #{expense['description']}"
    
    print "Nouveau montant (€) [#{expense['amount']}]: "
    new_amount = gets.chomp
    expense['amount'] = new_amount.to_f unless new_amount.empty?
    
    puts "\nCatégories disponibles:"
    @categories.each_with_index { |cat, i| puts "#{i + 1}. #{cat}" }
    print "Nouvelle catégorie [#{expense['category']}]: "
    new_category = gets.chomp
    unless new_category.empty?
      if new_category.match?(/^\d+$/)
        category_index = new_category.to_i - 1
        expense['category'] = @categories[category_index] if category_index >= 0 && category_index < @categories.length
      else
        expense['category'] = new_category
        add_category(new_category) unless @categories.include?(new_category)
      end
    end
    
    print "Nouvelle description [#{expense['description']}]: "
    new_description = gets.chomp
    expense['description'] = new_description unless new_description.empty?
    
    expense['updated_at'] = Time.now.to_s
    save_expenses
    
    puts "✅ Dépense modifiée avec succès !"
  end
  
  def delete_expense_interactive
    puts "\n🗑️ SUPPRIMER UNE DÉPENSE"
    puts "-" * 30
    
    if @expenses.empty?
      puts "📭 Aucune dépense à supprimer."
      return
    end
    
    list_expenses
    print "\nNuméro de la dépense à supprimer: "
    index = gets.chomp.to_i - 1
    
    if index < 0 || index >= @expenses.length
      puts "❌ Numéro invalide."
      return
    end
    
    expense = @expenses[index]
    puts "\nDépense à supprimer: #{expense['amount']}€ - #{expense['category']} - #{expense['description']}"
    print "Êtes-vous sûr ? (o/N): "
    
    confirmation = gets.chomp.downcase
    if confirmation == 'o' || confirmation == 'oui'
      @expenses.delete_at(index)
      save_expenses
      puts "✅ Dépense supprimée avec succès !"
    else
      puts "❌ Suppression annulée."
    end
  end
  
  def show_reports_menu
    puts "\n📈 RAPPORTS"
    puts "-" * 30
    puts "1. Rapport mensuel"
    puts "2. Rapport par catégorie"
    puts "3. Graphique des dépenses"
    puts "4. Retour au menu principal"
    print "Choisissez une option: "
    
    choice = gets.chomp
    case choice
    when '1'
      monthly_report
    when '2'
      category_report
    when '3'
      expense_chart
    when '4'
      return
    else
      puts "❌ Option invalide."
    end
  end
  
  def monthly_report
    # TODO: Implémenter le rapport mensuel
    puts "🚧 Rapport mensuel en cours de développement..."
  end
  
  def category_report
    # TODO: Implémenter le rapport par catégorie
    puts "🚧 Rapport par catégorie en cours de développement..."
  end
  
  def expense_chart
    # TODO: Implémenter le graphique ASCII
    puts "🚧 Graphique des dépenses en cours de développement..."
  end
  
  def manage_categories
    # TODO: Implémenter la gestion des catégories
    puts "🚧 Gestion des catégories en cours de développement..."
  end
  
  def export_menu
    # TODO: Implémenter l'export
    puts "🚧 Export des données en cours de développement..."
  end
  
  def load_expenses
    return [] unless File.exist?(DATA_FILE)
    JSON.parse(File.read(DATA_FILE))
  rescue JSON::ParserError
    []
  end
  
  def save_expenses
    File.write(DATA_FILE, JSON.pretty_generate(@expenses))
  end
  
  def load_categories
    default_categories = [
      'Alimentation', 'Transport', 'Logement', 'Santé', 
      'Loisirs', 'Vêtements', 'Éducation', 'Autres'
    ]
    
    # TODO: Charger depuis un fichier de configuration
    default_categories
  end
  
  def add_category(category)
    @categories << category unless @categories.include?(category)
    # TODO: Sauvegarder les catégories
  end
  
  def generate_id
    Time.now.to_f.to_s.gsub('.', '')
  end
end

# Lancement de l'application
if __FILE__ == $0
  ExpenseTracker.new.run
end