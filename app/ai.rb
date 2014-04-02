require 'sinatra/base'
require 'haml'
require 'pry'
require 'json'

class Ai < Sinatra::Base
  @@rules_array = []
  @@conditions_list = {}
  @@context_stack = {}
  @@main_aim
  @@aims_stack = []
  @@questions = []

  get '/' do
    parse_json
    create_conditions_list
    @message = "Hello"
    haml :index
  end
end