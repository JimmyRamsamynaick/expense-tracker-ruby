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
      puts "3. Voir les rapports"
      puts "4. Gérer les catégories"
      puts "5. Exporter les données"
      puts "6. Quitter"
      puts "="*50
      print "Choisissez une option (1-6): "
      
      choice = gets.chomp
      
      case choice
      when '1'
        add_expense_interactive
      when '2'
        list_expenses
      when '3'
        show_reports_menu
      when '4'
        manage_categories
      when '5'
        export_menu
      when '6'
        puts "👋 Au revoir !"
        break
      else
        puts "❌ Option invalide. Veuillez choisir entre 1 et 6."
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
    @expenses.sort_by { |e| e['date'] }.reverse.each do |expense|
      puts "#{expense['date']} | #{expense['amount']}€ | #{expense['category']} | #{expense['description']}"
      total += expense['amount']
    end
    
    puts "-" * 50
    puts "💰 Total: #{total}€"
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