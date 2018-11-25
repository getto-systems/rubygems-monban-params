require "date"

module Monban
  class Params
    class Error < RuntimeError; end

    def initialize(factory=Validator::Factory.new)
      @factory = factory
    end

    def validate(params)
      yield(@factory).call(:params, params)
    end

    class Validator
      def initialize(func,&message)
        @func = func
        @message = message
      end

      def call(key,value)
        @func.call(key,value) or raise Monban::Params::Error, "#{key} #{@message && @message.call} : [#{value}]"
      end

      class Factory
        def integer
          Validator.new(->(key,value){ value.is_a? Integer }){"must be integer"}
        end

        def string
          Validator.new(->(key,value){ value.is_a? String }){"must be string"}
        end

        def bool
          Validator.new(->(key,value){ value == true || value == false }){"must be boolean"}
        end


        def equal(val)
          Validator.new(->(key,value){ value == val }){"must equal #{val}"}
        end

        def in(values)
          Validator.new(->(key,value){ values.include?(value) }){"must be in [#{values}]"}
        end

        def not_empty
          Validator.new(->(key,value){ !value.respond_to?(:empty?) || !value.empty? }){"must not be empty"}
        end

        def not_nil
          Validator.new(->(key,value){ not value.nil? }){"must not be nil"}
        end

        def length(length)
          Validator.new(->(key,value){ value && value.length == length }){"'s length must equal #{length}"}
        end

        def match(pattern)
          Validator.new(->(key,value){ value && value.match?(pattern) }){"must match #{pattern}"}
        end

        def match_integer
          Validator.new(->(key,value){ value && value.to_i.to_s == value }){"must match integer pattern"}
        end

        def match_bool
          Validator.new(->(key,value){ value && ["true","false"].include?(value.to_s.downcase) }){"must match boolean pattern"}
        end

        def match_date
          Validator.new(->(key,value){
            begin
              value && Date.parse(value)
            rescue ArgumentError
              false
            end
          }){"must match date pattern"}
        end


        def hash(spec)
          Validator.new(->(key,value){
            value && spec.all?{|key,validator|
              value.has_key?(key) && validator.call(key, value[key])
            }
          }){"must satisfy hash spec"}
        end

        def hash_strict(spec)
          Validator.new(->(key,value){
            validators = spec.dup
            value && value.all?{|key,val|
              validators.delete(key).tap{|validator|
                break validator ? validator.call(key,val) : false
              }
            } && validators.empty?
          }){"must satisfy hash spec"}
        end


        def array(validator)
          Validator.new(->(key,value){
            value && value.is_a?(Array) && value.all?{|val| validator.call(key,val)}
          }){"must satisfy array spec"}
        end

        def array_include(values,&block)
          Validator.new(->(key,value){
            value && value.is_a?(Array) && value.all?{|val| values.include?(val)}
          }){"'s value must be in #{values}"}
        end


        def combine(validators)
          Validator.new(->(key,value){
            validators.all?{|validator| validator.call(key,value)}
          })
        end

        def allow_empty(validator)
          Validator.new(->(key,value){
            (value.respond_to?(:empty?) && value.empty?) or validator.call(key,value)
          })
        end
      end
    end
  end
end
