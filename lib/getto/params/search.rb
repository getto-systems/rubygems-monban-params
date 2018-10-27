module Getto
  class Params
    class Search
      def initialize(page:, limit:, sort:, query:)
        @page = Page.new(page: page, limit: limit)
        @sort = Sort.new(sort: sort)
        @query = Query.new(query: query)
      end

      def to_h
        @page.to_h.tap{|result|
          yield Worker.new(sort: @sort, query: @query, result: result)
        }
      end

      class Worker
        def initialize(sort:, query:, result:)
          @sort = sort
          @query = query
          @result = result
        end

        def sort(&block)
          @result.merge!(sort: @sort.to_h(&block))
        end

        def query(&block)
          @result.merge!(query: @query.to_h(&block))
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

        def to_h
          spec = {}
          yield Order.new(spec)

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

        def to_h
          spec = {}
          yield Checker.new(spec)

          spec.map{|key,checker|
            if search = @query[key]
              if checker.call(search)
                [key.to_sym, search]
              end
            end
          }.compact.to_h
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

          def not_all_empty
            ->(search){ not search.all?(&:empty?) }
          end
        end
      end
    end
  end
end
