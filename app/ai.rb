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
      aims = [""]
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
    clear_variables
    parse_json
    create_conditions_list
    haml :index
  end

  post '/result' do
    @@main_aim = params[:aim]
    params[:context].each do |key,value|
      @@context_stack[key.gsub('-', ' ')] = value unless value.empty?
    end
    calculate
  end

  post '/additional_info' do
    @@context_stack[@@aims_stack.last[0]] = params[:additional_info]
    write_log("ответ на вопрос: #{@@aims_stack.last[0]}? #{params[:additional_info]}")
    a = @@aims_stack.pop
    calculate(a[1])
  end

  private

  def calculate(number=nil)
    a = main_method(number)
    if a
      @aim = @@main_aim
      @result = @@context_stack[@aim]
      haml :result
    else
      @input_param = @@aims_stack.last[0]
      @values = input_list[@input_param]
      if @input_param == @@main_aim
        @aim = @@main_aim
        @result = "невозможно определить"
        haml :result
      else
        haml :aditional_info
      end
    end
  end

  def parse_json
    file = open(File.expand_path('database.json', settings.public_folder))
    json = file.read
    file.close
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

  def main_method(q_num=nil)
    @@aims_stack << [@@main_aim, -1] && write_log("стек целей: #{@@main_aim}") unless q_num
    b = false
    until b
      last_aim = @@aims_stack.last[0]
      rule_number = q_num ? q_num : find_rule_number(@@aims_stack.last[0])
      q_num = nil
      if rule_number
        b = analyze_rule(rule_number, last_aim)
      else
        return false
      end
    end
    @@context_stack[@@main_aim]
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
          message = "истина, контекстный стек: #{aim} - #{@@context_stack[aim]}"
          write_log("Правило #{rule_number}: #{message}" )
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
      message = "ложь"
      write_log("Правило #{rule_number}: #{message}" )

    when 0
      r = find_rule_by_id(rule_number)
      r.conditions.each do |key, value|
        unless @@context_stack.key?(key)
          @@aims_stack << [key, rule_number]
          message = "неизвестно, стек целей: #{key}, правило #{rule_number}"
          write_log("Правило #{rule_number}: #{message}" )
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
          r.mark = :forbid
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

  def clear_variables
    @@rules_array.clear
    @@conditions_list.clear
    @@context_stack.clear
    @@aims_stack.clear
    @@questions.clear
    file = open(File.expand_path('log.txt', settings.public_folder), "w")
    file << '' 
    file.close
  end

  def write_log(message)
    file = open(File.expand_path('log.txt', settings.public_folder), "a")
    file << message + "\n" 
    file.close
  end
end
