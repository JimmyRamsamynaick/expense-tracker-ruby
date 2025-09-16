#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/json'
require 'json'
require 'csv'
require 'date'

# Configuration Sinatra
set :port, 4567
set :bind, '0.0.0.0'
set :public_folder, 'public'
set :views, 'views'

class ExpenseTrackerWeb < Sinatra::Base
  DATA_FILE = 'expenses.json'
  CATEGORIES_FILE = 'categories.json'
  
  configure do
    enable :sessions
    set :session_secret, 'expense_tracker_secret_key_2024'
  end
  
  # Routes principales
  get '/' do
    @expenses = load_expenses
    @categories = load_categories
    @total = @expenses.sum { |e| e['amount'] }
    @recent_expenses = @expenses.sort_by { |e| e['date'] }.reverse.first(5)
    erb :index
  end
  
  get '/expenses' do
    @expenses = load_expenses.sort_by { |e| e['date'] }.reverse
    @categories = load_categories
    @total = @expenses.sum { |e| e['amount'] }
    erb :expenses
  end
  
  post '/expenses' do
    expense = {
      id: generate_id,
      amount: params[:amount].to_f,
      category: params[:category],
      description: params[:description],
      date: params[:date] || Date.today.to_s,
      created_at: Time.now.to_s
    }
    
    expenses = load_expenses
    expenses << expense
    save_expenses(expenses)
    
    # Ajouter la catégorie si elle n'existe pas
    categories = load_categories
    unless categories.include?(params[:category])
      categories << params[:category]
      save_categories(categories)
    end
    
    redirect '/expenses'
  end
  
  get '/expenses/:id/edit' do
    @expense = load_expenses.find { |e| e['id'] == params[:id] }
    @categories = load_categories
    erb :edit_expense
  end
  
  post '/expenses/:id' do
    expenses = load_expenses
    expense = expenses.find { |e| e['id'] == params[:id] }
    
    if expense
      expense['amount'] = params[:amount].to_f
      expense['category'] = params[:category]
      expense['description'] = params[:description]
      expense['date'] = params[:date]
      expense['updated_at'] = Time.now.to_s
      
      save_expenses(expenses)
      
      # Ajouter la catégorie si elle n'existe pas
      categories = load_categories
      unless categories.include?(params[:category])
        categories << params[:category]
        save_categories(categories)
      end
    end
    
    redirect '/expenses'
  end
  
  delete '/expenses/:id' do
    expenses = load_expenses
    expenses.reject! { |e| e['id'] == params[:id] }
    save_expenses(expenses)
    
    content_type :json
    { success: true }.to_json
  end
  
  get '/categories' do
    @categories = load_categories
    @expenses = load_expenses
    erb :categories
  end
  
  post '/categories' do
    categories = load_categories
    new_category = params[:name].strip
    
    unless categories.include?(new_category) || new_category.empty?
      categories << new_category
      save_categories(categories)
    end
    
    redirect '/categories'
  end
  
  delete '/categories/:name' do
    categories = load_categories
    expenses = load_expenses
    category_to_delete = params[:name]
    
    # Déplacer les dépenses vers "Autres"
    expenses.each { |e| e['category'] = 'Autres' if e['category'] == category_to_delete }
    save_expenses(expenses)
    
    # Supprimer la catégorie
    categories.delete(category_to_delete)
    categories << 'Autres' unless categories.include?('Autres')
    save_categories(categories)
    
    content_type :json
    { success: true }.to_json
  end
  
  get '/reports' do
    @expenses = load_expenses
    @categories = load_categories
    
    # Statistiques générales
    @total = @expenses.sum { |e| e['amount'] }
    @count = @expenses.length
    @average = @count > 0 ? (@total / @count).round(2) : 0
    
    # Dépenses par catégorie
    @category_totals = @categories.map do |category|
      total = @expenses.select { |e| e['category'] == category }.sum { |e| e['amount'] }
      { name: category, total: total, count: @expenses.count { |e| e['category'] == category } }
    end.sort_by { |c| -c[:total] }
    
    # Dépenses par mois
    @monthly_totals = @expenses.group_by { |e| e['date'][0..6] }.map do |month, expenses|
      { month: month, total: expenses.sum { |e| e['amount'] }, count: expenses.length }
    end.sort_by { |m| m[:month] }.reverse
    
    erb :reports
  end
  
  get '/export' do
    @expenses = load_expenses
    erb :export
  end
  
  get '/export/csv' do
    expenses = load_expenses
    
    content_type 'application/csv'
    attachment 'expenses.csv'
    
    CSV.generate do |csv|
      csv << ['Date', 'Montant', 'Catégorie', 'Description']
      expenses.each do |expense|
        csv << [expense['date'], expense['amount'], expense['category'], expense['description']]
      end
    end
  end
  
  get '/export/json' do
    expenses = load_expenses
    
    content_type 'application/json'
    attachment 'expenses.json'
    
    JSON.pretty_generate(expenses)
  end
  
  # API Routes
  get '/api/expenses' do
    content_type :json
    load_expenses.to_json
  end
  
  get '/api/categories' do
    content_type :json
    load_categories.to_json
  end
  
  get '/api/stats' do
    expenses = load_expenses
    
    content_type :json
    {
      total_amount: expenses.sum { |e| e['amount'] },
      total_count: expenses.length,
      categories_count: load_categories.length,
      average_expense: expenses.length > 0 ? (expenses.sum { |e| e['amount'] } / expenses.length).round(2) : 0
    }.to_json
  end
  
  private
  
  def load_expenses
    return [] unless File.exist?(DATA_FILE)
    JSON.parse(File.read(DATA_FILE))
  rescue JSON::ParserError
    []
  end
  
  def save_expenses(expenses)
    File.write(DATA_FILE, JSON.pretty_generate(expenses))
  end
  
  def load_categories
    return JSON.parse(File.read(CATEGORIES_FILE)) if File.exist?(CATEGORIES_FILE)
    
    default_categories = [
      'Alimentation', 'Transport', 'Logement', 'Santé', 
      'Loisirs', 'Vêtements', 'Éducation', 'Autres'
    ]
    
    save_categories(default_categories)
    default_categories
  rescue JSON::ParserError
    default_categories = [
      'Alimentation', 'Transport', 'Logement', 'Santé', 
      'Loisirs', 'Vêtements', 'Éducation', 'Autres'
    ]
    save_categories(default_categories)
    default_categories
  end
  
  def save_categories(categories)
    File.write(CATEGORIES_FILE, JSON.pretty_generate(categories))
  end
  
  def generate_id
    Time.now.to_f.to_s.gsub('.', '')
  end
end

# Lancement de l'application
if __FILE__ == $0
  ExpenseTrackerWeb.run!
end