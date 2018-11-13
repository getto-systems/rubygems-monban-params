require "date"

module Getto
  class Params
    def initialize(factory=Validator::Factory.new)
      @factory = factory
    end

    def validate(params)
      yield(@factory).call(params)
    end

    class Validator
      def initialize(func,&failed)
        @func = func
        @failed = failed
      end

      def call(params)
        @func.call(params).tap{|is_valid|
          unless is_valid
            @failed && @failed.call(params)
          end
        }
      end

      class Factory
        def integer(&block)
          Validator.new(->(value){ value.is_a? Integer }, &block)
        end

        def string(&block)
          Validator.new(->(value){ value.is_a? String }, &block)
        end

        def bool(&block)
          Validator.new(->(value){ value == true || value == false }, &block)
        end


        def equal(val,&block)
          Validator.new(->(value){ value == val }, &block)
        end

        def in(values,&block)
          Validator.new(->(value){ values.include?(value) }, &block)
        end

        def not_empty(&block)
          Validator.new(->(value){ not value.empty? }, &block)
        end

        def length(length,&block)
          Validator.new(->(value){ value && value.length == length }, &block)
        end

        def match(pattern,&block)
          Validator.new(->(value){ value && value.match?(pattern) }, &block)
        end

        def match_integer(&block)
          Validator.new(->(value){ value && value.to_i.to_s == value }, &block)
        end

        def match_bool(&block)
          Validator.new(->(value){ value && ["true","false"].include?(value.to_s.downcase) }, &block)
        end

        def match_date(&block)
          Validator.new(->(value){
            begin
              value && Date.parse(value)
            rescue ArgumentError
              false
            end
          }, &block)
        end


        def hash(spec,&block)
          Validator.new(->(value){
            value && spec.all?{|key,validator|
              value.has_key?(key) && validator.call(value[key])
            }
          }, &block)
        end

        def hash_strict(spec,&block)
          Validator.new(->(value){
            validators = spec.dup
            value && value.all?{|key,val|
              validators.delete(key).tap{|validator|
                break validator ? validator.call(val) : false
              }
            } && validators.empty?
          }, &block)
        end


        def array(validator,&block)
          Validator.new(->(value){
            value && value.is_a?(Array) && value.all?{|val| validator.call(val)}
          }, &block)
        end

        def array_include(values,&block)
          Validator.new(->(value){
            value && value.is_a?(Array) && value.all?{|val| values.include?(val)}
          }, &block)
        end


        def combine(validators,&block)
          Validator.new(->(value){
            validators.all?{|validator| validator.call(value)}
          }, &block)
        end


        def allow_empty(validator,&block)
          Validator.new(->(value){
            value.empty? or validator.call(value)
          }, &block)
        end
      end
    end
  end
end
