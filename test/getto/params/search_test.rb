require "test_helper"

require "getto/params/search"

module Getto::Params::SearchTest
  class Time
    def parse(str)
      ::Time.parse(str)
    end
  end

  describe Getto::Params::Search do

    describe "search params" do
      it "returns all search params" do
        page = 1
        limit = 1000
        sort = "login_id.asc"
        query = {
          "login_id.cont" => "search",
          "date.gteq" => "2018-10-01",
          "time.gteq" => "2018-10-01",
          "time.lteq" => "2018-10-01",
        }

        time = Time.new

        assert_equal(
          Getto::Params::Search.new(page: page, limit: limit, sort: sort, query: query).to_h do |search|
            search.sort do |s|
              s.straight :login_id
            end
            search.convert do |c|
              c.convert "date.gteq", &c.to_date
              c.convert "time.gteq", &c.to_beginning_of_day(time)
              c.convert "time.lteq", &c.to_end_of_day(time)
            end
            search.query do |q|
              q.search "login_id.cont", &q.not_empty
              q.search "date.gteq", &q.not_nil
              q.search "time.gteq", &q.not_nil
              q.search "time.lteq", &q.not_nil
            end
          end,
          {
            limit: 1000,
            offset: 0,
            sort: {
              column: :login_id,
              order: true,
            },
            query: {
              "login_id.cont": "search",
              "date.gteq": ::Date.parse("2018-10-01"),
              "time.gteq": ::Time.parse("2018-10-01 00:00:00"),
              "time.lteq": ::Time.parse("2018-10-01 23:59:59"),
            },
          }
        )
      end
    end

    describe "page params" do
      it "returns limit and offset" do
        assert_equal(
          Getto::Params::Search::Page.new(page: 1, limit: 1000).to_h,
          {
            limit: 1000,
            offset: 0,
          }
        )
        assert_equal(
          Getto::Params::Search::Page.new(page: 2, limit: 1000).to_h,
          {
            limit: 1000,
            offset: 1000,
          }
        )
        assert_equal(
          Getto::Params::Search::Page.new(page: 3, limit: 1000).to_h,
          {
            limit: 1000,
            offset: 2000,
          }
        )
      end
    end

    describe "sort params" do
      it "returns sort as straight order" do
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.asc").to_h(sort: ->(s){
            s.straight :login_id
          }),
          {
            column: :login_id,
            order: true,
          }
        )
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.desc").to_h(sort: ->(s){
            s.straight :login_id
          }),
          {
            column: :login_id,
            order: false,
          }
        )
      end

      it "returns sort as invert order" do
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.asc").to_h(sort: ->(s){
            s.invert :login_id
          }),
          {
            column: :login_id,
            order: false,
          }
        )
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.desc").to_h(sort: ->(s){
            s.invert :login_id
          }),
          {
            column: :login_id,
            order: true,
          }
        )
      end

      it "returns empty when unknown column specified" do
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "unknown.asc").to_h(sort: ->(s){
            s.straight :login_id
          }),
          {
            column: nil,
            order: true,
          }
        )
      end
    end

    describe "convert" do
      it "returns nil with invalid date" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "date.lteq" => "search",
          }).to_h(convert: ->(c){
            c.convert "date.lteq", &c.to_date
          }, check: ->(q){
            q.search "date.lteq", &q.not_nil
          }),
          {
          }
        )
      end

      it "returns nil with invalid time" do
        time = Time.new

        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "time.gteq" => "search",
            "time.lteq" => "search",
          }).to_h(convert: ->(c){
            c.convert "time.gteq", &c.to_beginning_of_day(time)
            c.convert "time.lteq", &c.to_end_of_day(time)
          }, check: ->(q){
            q.search "time.gteq", &q.not_nil
            q.search "time.lteq", &q.not_nil
          }),
          {
          }
        )
      end
    end

    describe "not_empty" do
      it "returns query with valid search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.cont" => "search",
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.cont", &q.not_empty
          }),
          {
            "login_id.cont": "search",
          }
        )
      end

      it "returns empty with empty search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.cont" => "",
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.cont", &q.not_empty
          }),
          {
          }
        )
      end

      it "returns empty with unknown search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "unknown.cont" => "",
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.cont", &q.not_empty
          }),
          {
          }
        )
      end
    end

    describe "not_all_empty" do
      it "returns query with valid search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.in" => ["search"],
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.in", &q.not_all_empty
          }),
          {
            "login_id.in": ["search"],
          }
        )
      end

      it "returns empty with empty search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.in" => [],
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.in", &q.not_all_empty
          }),
          {
          }
        )
      end

      it "returns empty with all empty value" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.in" => ["", ""],
          }).to_h(convert: nil, check: ->(q){
            q.search "login_id.in", &q.not_all_empty
          }),
          {
          }
        )
      end
    end
  end
end
