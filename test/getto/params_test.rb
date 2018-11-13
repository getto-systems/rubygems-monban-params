require "test_helper"

require "getto/params"

module Getto::ParamsTest
  class AppError < RuntimeError
  end

  describe Getto::Params do
    describe "validates" do
      it "success if all validation satisfied" do
        params = {
          "name"  => "value",
          "token" => "TOKEN",
          "key"   => "KEY",
          "str1"  => "param1",
          "str2"  => "param2",
          "tel"   => "080-1234-5678",
          "date"  => "2018-10-01",
          "number" => "1234",
          "bool"  => "True",
          "hash"  => {
            "array" => ["value"],
            "keys" => ["key1","key2"],
            "params" => {
              "key" => 128,
              "bool" => true,
            },
          },
          "object" => {
            "key" => 128,
            "bool" => true,
          },
        }

        assert(
          Getto::Params.new.validate(params) do |v|
            v.hash(
              "name"  => v.combine([v.string, v.not_empty]),
              "token" => v.combine([v.string, v.length(5)]),
              "key"   => v.equal("KEY"),
              "str1"  => v.in(["param1","param2"]),
              "str2"  => v.in(["param1","param2"]),
              "tel"   => v.combine([v.string, v.match(%r{\A[0-9]+-[0-9]+-[0-9]+\Z})]),
              "date"  => v.combine([v.string, v.match_date]),
              "number" => v.match_integer,
              "bool"  => v.match_bool,
              "hash"  => v.hash(
                "array" => v.array(v.string),
                "keys" => v.array_include(["key1","key2","key3"]),
                "params" => v.hash(
                  "key" => v.integer,
                  "bool" => v.bool,
                ),
              ),
              "object" => v.hash_strict(
                "key" => v.integer,
                "bool" => v.bool,
              ),
            )
          end
        )
      end

      it "failed if any validation failed" do
        params = {
          "name" => "",
          "hash" => {
            "array" => ["value"],
            "params" => {
              "key" => 128,
              "bool" => true,
            },
          }
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.combine([v.string, v.not_empty]),
              "hash" => v.hash(
                "array" => v.array(v.string),
                "params" => v.hash(
                  "key" => v.integer,
                  "bool" => v.bool,
                ),
              ),
            )
          end
        )
      end

      it "call additional block with value if validation failed" do
        params = {
          "name" => "",
        }

        assert_raises AppError do
          Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.combine([v.string, v.not_empty]){|val| raise AppError, val},
            )
          end
        end
      end
    end

    describe "equal" do
      it "failed with other data" do
        params = {
          "name" => "value",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.equal("KEY"),
            )
          end
        )
      end
    end

    describe "in" do
      it "failed with other string data" do
        params = {
          "name" => "value",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.in(["value1","value2"]),
            )
          end
        )
      end
    end

    describe "length" do
      it "failed with different length" do
        params = {
          "name" => "value",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.length(3),
            )
          end
        )
      end
    end

    describe "match" do
      it "failed with unmatch pattern" do
        params = {
          "name" => "090-xxxx-xxxx",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.match(%r{\A[0-9]+-[0-9]+-[0-9]+\Z}),
            )
          end
        )
      end
    end

    describe "match_integer" do
      it "failed with not integer pattern" do
        params = {
          "name" => "09",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.match_integer,
            )
          end
        )
      end
    end

    describe "match_bool" do
      it "failed with not bool pattern" do
        params = {
          "name" => "null",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.match_bool,
            )
          end
        )
      end
    end

    describe "match_date" do
      it "failed with invalid date" do
        params = {
          "date" => "2018-02-29",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "date" => v.match_date,
            )
          end
        )
      end
    end

    describe "hash" do
      it "ignore another data in params" do
        params = {
          "name" => "value",
          "hash" => {
            "array" => ["value"],
            "params" => {
              "key" => 128,
              "bool" => true,
            },
          }
        }

        assert(
          Getto::Params.new.validate(params) do |v|
            v.hash(
              "name" => v.combine([v.string, v.not_empty]),
            )
          end
        )
      end
    end

    describe "hash_strict" do
      it "failed with another data" do
        params = {
          "name" => "value",
          "another" => "data",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash_strict(
              "name" => v.combine([v.string, v.not_empty]),
            )
          end
        )
      end

      it "failed missing key" do
        params = {
          "name" => "value",
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash_strict(
              "name"  => v.combine([v.string, v.not_empty]),
              "value" => v.combine([v.string, v.not_empty]),
            )
          end
        )
      end
    end

    describe "array_include" do
      it "failed with another data" do
        params = {
          "keys" => ["value0","value1"],
        }

        assert(
          !Getto::Params.new.validate(params) do |v|
            v.hash(
              "keys" => v.array_include(["value1","value2","value3"]),
            )
          end
        )
      end

      it "success with empty array" do
        params = {
          "keys" => [],
        }

        assert(
          Getto::Params.new.validate(params) do |v|
            v.hash(
              "keys" => v.array_include(["value1","value2","value3"]),
            )
          end
        )
      end
    end

    describe "allow_empty" do
      it "pass through with empty data" do
        params = {
          "keys" => [""],
        }

        assert(
          Getto::Params.new.validate(params) do |v|
            v.hash(
              "keys" => v.array(v.allow_empty(v.match_integer)),
            )
          end
        )
      end
    end
  end
end
