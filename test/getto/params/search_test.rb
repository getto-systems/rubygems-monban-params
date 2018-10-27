require "test_helper"

require "getto/params/search"

module Getto::Params::SearchTest
  describe Getto::Params::Search do

    describe "search params" do
      it "returns all search params" do
        page = 1
        limit = 1000
        sort = "login_id.asc"
        query = {
          "login_id.cont" => "search",
        }

        assert_equal(
          Getto::Params::Search.new(page: page, limit: limit, sort: sort, query: query).to_h do |search|
            search.sort do |s|
              s.straight :login_id
            end
            search.query do |q|
              q.search "login_id.cont", &q.not_empty
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
          Getto::Params::Search::Sort.new(sort: "login_id.asc").to_h do |s|
            s.straight :login_id
          end,
          {
            column: :login_id,
            order: true,
          }
        )
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.desc").to_h do |s|
            s.straight :login_id
          end,
          {
            column: :login_id,
            order: false,
          }
        )
      end

      it "returns sort as invert order" do
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.asc").to_h do |s|
            s.invert :login_id
          end,
          {
            column: :login_id,
            order: false,
          }
        )
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "login_id.desc").to_h do |s|
            s.invert :login_id
          end,
          {
            column: :login_id,
            order: true,
          }
        )
      end

      it "returns empty when unknown column specified" do
        assert_equal(
          Getto::Params::Search::Sort.new(sort: "unknown.asc").to_h do |s|
            s.straight :login_id
          end,
          {
            column: nil,
            order: true,
          }
        )
      end
    end

    describe "not_empty" do
      it "returns query with valid search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.cont" => "search",
          }).to_h do |q|
            q.search "login_id.cont", &q.not_empty
          end,
          {
            "login_id.cont": "search",
          }
        )
      end

      it "returns empty with empty search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.cont" => "",
          }).to_h do |q|
            q.search "login_id.cont", &q.not_empty
          end,
          {
          }
        )
      end

      it "returns empty with unknown search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "unknown.cont" => "",
          }).to_h do |q|
            q.search "login_id.cont", &q.not_empty
          end,
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
          }).to_h do |q|
            q.search "login_id.in", &q.not_all_empty
          end,
          {
            "login_id.in": ["search"],
          }
        )
      end

      it "returns empty with empty search" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.in" => [],
          }).to_h do |q|
            q.search "login_id.in", &q.not_all_empty
          end,
          {
          }
        )
      end

      it "returns empty with all empty value" do
        assert_equal(
          Getto::Params::Search::Query.new(query: {
            "login_id.in" => ["", ""],
          }).to_h do |q|
            q.search "login_id.in", &q.not_all_empty
          end,
          {
          }
        )
      end
    end
  end
end
