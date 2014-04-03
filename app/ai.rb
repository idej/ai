require 'sinatra/base'
require 'haml'
require 'pry'
require 'json'
require_relative 'question.rb'

class Ai < Sinatra::Base
  @@rules_array = []
  @@conditions_list = {}
  @@context_stack = {}
  @@main_aim
  @@aims_stack = []
  @@questions = []

  helpers do
    def aims_options
      aims = [" "]
      aims += @@rules_array.map{ |r| r.result.keys.first }
      aims.uniq
    end

    def input_list
      list = @@conditions_list
      @@rules_array.map do |r|
        key = r.result.keys.first
        value = r.result.values.first
        list[key] = [] unless list.key?(key)
        list[key] << value unless list[key].include?(value)
      end
      list
    end
  end

  get '/' do
    parse_json
    create_conditions_list
    haml :index
  end

  post '/result' do
    binding.pry
   # haml :index
  end

  private

  def parse_json
    file = open(File.expand_path('database.json', settings.public_folder))
    json = file.read
    parsed = JSON.parse(json)
    parsed["questions"].each do |que|
      q = Question.new(que)
      @@rules_array << q
    end
    @@rules_array
  end

  def create_conditions_list
    @@rules_array.each do |elem|
      elem.conditions.each do |key, value|
        @@conditions_list[key] = [] unless @@conditions_list.key?(key)
        @@conditions_list[key] << value unless @@conditions_list[key].include?(value)
      end
    end
  end

  def main_method
    @@aims_stack << [@@main_aim, -1]
    b = false
    until b
      last_aim = @@aims_stack.last[0]
      rule_number = find_rule_number(@@aims_stack.last[0])
      if (rule_number != nil)
        b = analyze_rule(rule_number, last_aim)
      else
        puts "Введите значение параметра #{@@aims_stack.last[0]}"
        value = gets.chomp
        @@context_stack[@@aims_stack.last[0]] = value
        a = @@aims_stack.pop
        b = analyze_rule(a[1], @@aims_stack.last[0])
      end
    end


    p @@context_stack[@@main_aim]
  end

  def find_rule_number(aim)
    a = @@rules_array.select {|r|
      r.result.key?(aim) && r.mark != :forbid
    }
    a.first.id unless a.empty?
  end

  def analyze_rule(rule_number, aim)
    return_value = false

    case can_find_aim?(rule_number, aim)

    when 1
      @@rules_array.each do |r|
        if (r.id == rule_number)
          @@context_stack[aim] = r.result[aim]
          r.mark = :accept
          break
        end
      end
      @@aims_stack.pop
      return_value = true if @@aims_stack.empty?

    when -1
      @@rules_array.each do |r|
        if (r.id == rule_number)
          r.mark = :forbid
          break
        end
      end

    when 0
      r = find_rule_by_id(rule_number)
      r.conditions.each do |key, value|
        unless @@context_stack.key?(key)
          @@aims_stack << [key, rule_number]
          break
        end
      end
    end

    return_value
  end

  def can_find_aim?(rule_number, aim)
    return_value = 1

    r = find_rule_by_id(rule_number)
    r.conditions.each do |key, value|
      if @@context_stack.key?(key)
        unless @@context_stack[key] == value
          return_value = -1
          break
        end
      else
        return_value = 0
      end
    end

    return_value
  end

  def find_rule_by_id(rule_number)
     @@rules_array.each do |r|
      if (r.id == rule_number)
        return r
      end
    end
  end
end
