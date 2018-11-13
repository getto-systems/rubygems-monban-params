module Getto
  class Params
    class Search
      def initialize(page:, limit:, sort:, query:)
        @page = Page.new(page: page, limit: limit)
        @sort = Sort.new(sort: sort)
        @query = Query.new(query: query)
      end

      def to_h
        worker = Worker.new
        yield worker

        @page.to_h
          .merge(sort: @sort.to_h(sort: worker.instance_variable_get(:@sort)))
          .merge(query: @query.to_h(
            convert: worker.instance_variable_get(:@convert),
            check:   worker.instance_variable_get(:@check),
          ))
      end

      class Worker
        def sort(&block)
          @sort = block
        end

        def convert(&block)
          @convert = block
        end

        def query(&block)
          @check = block
        end
      end

      class Page
        def initialize(page:, limit:)
          @page  = page
          @limit = limit
        end

        def to_h
          {
            limit: @limit,
            offset: (@page.to_i - 1) * @limit,
          }
        end
      end

      class Sort
        def initialize(sort:)
          @sort = [sort.split(".")].to_h
        end

        def to_h(sort:)
          spec = {}
          if sort
            sort.call Order.new(spec)
          end

          result = {
            column: nil,
            order: true,
          }

          spec.map{|key,is_straight|
            if sort = @sort[key]
              result[:column] = key.to_sym
              result[:order] =
                if sort == "asc"
                  is_straight
                else
                  not is_straight
                end
            end
          }

          result
        end

        class Order
          def initialize(columns)
            @columns = columns
          end

          def straight(column)
            @columns[column.to_s] = true
          end

          def invert(column)
            @columns[column.to_s] = false
          end
        end
      end

      class Query
        def initialize(query:)
          @query = query
        end

        def to_h(convert:, check:)
          converters = {}
          if convert
            convert.call Converter.new(converters)
          end

          checkers = {}
          if check
            check.call Checker.new(checkers)
          end

          query = @query.map{|key,search|
            if converter = converters[key.to_s]
              [key.to_s, converter.call(search)]
            else
              [key.to_s, search]
            end
          }.to_h

          checkers.map{|key,checker|
            if search = query[key]
              if checker.call(search)
                [key, search]
              end
            end
          }.compact.to_h.transform_keys(&:to_sym)
        end

        class Converter
          def initialize(columns)
            @columns = columns
          end

          def convert(column,&converter)
            @columns[column.to_s] = converter
          end


          def to_date
            ->(search) {
              begin
                ::Date.parse(search)
              rescue ArgumentError
                nil
              end
            }
          end

          def to_beginning_of_day(time)
            ->(search){
              begin
                time.parse(search).to_date.to_time
              rescue ArgumentError
                nil
              end
            }
          end

          def to_end_of_day(time)
            ->(search){
              begin
                (time.parse(search).to_date + 1).to_time - 1
              rescue ArgumentError
                nil
              end
            }
          end
        end

        class Checker
          def initialize(columns)
            @columns = columns
          end

          def search(column,&checker)
            @columns[column.to_s] = checker
          end


          def not_empty
            ->(search){ not search.empty? }
          end

          def not_nil
            ->(search){ not search.nil? }
          end

          def not_all_empty
            ->(search){ not search.all?(&:empty?) }
          end
        end
      end
    end
  end
end
