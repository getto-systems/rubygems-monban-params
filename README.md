# getto-params

[rubygems: getto-params](https://rubygems.org/gems/getto-params)

Validate parameters like strong-parameters(rails)

```ruby
require "getto/params"

Getto::Params.new.validate(params) do |v|
  v.hash(
    "name"  => v.combine([v.string, v.not_empty]){|val|
      raise ArgumentError, "name should be not empty string: #{val}"
    },
    "token" => v.combine([v.string, v.allow_empty(v.length(5))]),
    "key"   => v.equal("KEY"),
    "str1"  => v.in(["param1","param2"]),
    "str2"  => v.in(["param1","param2"]),
    "tel"   => v.combine([v.string, v.match(%r{\A[0-9]+-[0-9]+-[0-9]+\Z})]),
    "date"  => v.combine([v.string, v.match_date]),
    "data"  => v.not_nil,
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
# => true  : success
# => false : fail
```

- misc: format parameters for search

```ruby
require "getto/params/search"

time = Time # respond to `parse`

Getto::Params::Search.new(
  page:  1,
  limit: 1000,
  sort: "name.asc",
  query: {
    "name.cont" => "search",
    "value.eq"  => "value1",
    "date.lteq" => "2018-10-01",
    "time.gteq" => "2018-10-01",
    "time.lteq" => "2018-10-01",
  },
).to_h do |search|
  search.sort do |s|
    s.straight :name
  end

  search.convert do |c|
    c.convert "date.lteq", &c.to_date
    c.convert "time.gteq", &c.to_beginning_of_day(time)
    c.convert "time.lteq", &c.to_end_of_day(time)
  end

  search.query do |q|
    q.search "name.cont", &q.not_empty
    q.search("value.eq"){|val| ["value1","value2"].include? val }

    q.search "date.lteq", &q.not_nil
    q.search "time.gteq", &q.not_nil
    q.search "time.lteq", &q.not_nil
  end
end
# => {
#   limit: 1000,
#   offset: 0,
#   sort: {
#     column: :name,
#     order: true,
#   },
#   query: {
#     "name.cont": "search",
#     "value.eq":  "value1",
#     "date.lteq":  Date.parse("2018-10-01"),
#     "time.gteq":  Time.parse("2018-10-01 00:00:00"),
#     "time.lteq":  Time.parse("2018-10-01 23:59:59"),
#   },
# }
```


###### Table of Contents

- [Requirements](#Requirements)
- [Usage](#Usage)
- [License](#License)

<a id="Requirements"></a>
## Requirements

- developed on ruby: 2.5.1


<a id="Usage"></a>
## Usage

```ruby
require "getto/params"

Getto::Params.new.validate(params) do |v|
  # argument `params` should be hash
  v.hash(
    # should be String
    "key" => v.string,

    # should be Integer
    "key" => v.integer,

    # should be Boolean
    "key" => v.bool,


    # should be equal to "value"
    "key" => v.equal("value"),

    # should be equal to "value1" or "value2"
    "key" => v.in(["value1","value2"]),

    # should not be empty
    "key" => v.not_empty,

    # length should be 10,
    "key" => v.length(10),

    # should match %r{example}
    "key" => v.match(%r{example}),

    # should match integer (value is string, but seem to be a Integer)
    "key" => v.match_integer,

    # downcase should be equal to "true" or "false"
    "key" => v.match_bool,

    # should match date
    "key" => v.match_date,


    # should be hash includes :key that value is string
    "key" => v.hash(
      key: v.string,
    ),

    # should be hash only includes :key that value is string
    "key" => v.hash_strict(
      key: v.string,
    ),


    # should be array that has string value
    "key" => v.array(v.string),

    # should be array that has "value1" or "value2"
    "key" => v.array_include(["value1","value2"])


    # should be match integer if value is not empty
    "key" => v.allow_empty(v.match_integer),


    # validate string and not_empty
    "key" => v.combine([v.string, v.not_empty]),

    # validate not_nil
    "key" => v.not_nil,


    # raise error if valudation failed
    "key" => v.string{|val| raise ArgumentError, "key should be string: #{val}" }
  )
end
# => true  : success
# => false : fail
```


### Getto::Params::Search

Format parameters for search api

```ruby
require "getto/params/search"

time = Time # respond to `parse`

Getto::Params::Search.new(
  page:  1,
  limit: 1000,
  sort: "name.asc",
  query: {
    "name.cont" => "search",
  },
).to_h do |search|

  search.sort do |s|
    # sort name as straight order
    s.straight :name

    # sort name as invert order
    s.invert :name
  end

  search.convert do |c|
    c.convert "date.lteq", &c.to_date
    c.convert "time.gteq", &c.to_beginning_of_day(time)
    c.convert "time.lteq", &c.to_end_of_day(time)
  end

  search.query do |q|
    # search "name.cont" if value not empty
    q.search "name.cont", &q.not_empty

    # search "name.in" if any values not empty
    q.search "name.in", &q.not_all_empty
  end

end
```

#### pages

```ruby
# page: 1, limit: 1000
# => {
#  limit:  1000,
#  offset: 0,
# }

# page: 2, limit: 1000
# => {
#  limit:  1000,
#  offset: 1000,
# }
```

#### sort order

- straight order

```ruby
search.sort do |s|
  # sort name as straight order
  s.straight :name
end

# sort: "name.asc"
# => sort: {
#   column: :name,
#   order: true, # asc => true
# }

# sort: "name.desc"
# => sort: {
#   column: :name,
#   order: false, # desc => false
# }
```

- invert order

```ruby
search.sort do |s|
  # sort name as invert order
  s.invert :name
end

# sort: "name.asc"
# => sort: {
#   column: :name,
#   order: false, # asc => false
# }

# sort: "name.desc"
# => sort: {
#   column: :name,
#   order: true, # desc => true
# }
```

#### convert query

- to date

```ruby
search.convert do |c|
  c.convert "date.lteq", &c.to_date
end

# query: { "date.lteq" => "invalid date" }
# => query: {
#   "date.lteq" => nil,
# }

# query: { "date.lteq" => "2018-10-01" }
# => query: {
#   "date.lteq" => Date.parse("2018-10-01"),
# }
```

- to beginning of day, to end of day

```ruby
time = Time # respond to `parse`

search.convert do |c|
  c.convert "time.gteq", &c.to_beginning_of_day(time)
  c.convert "time.lteq", &c.to_end_of_day(time)
end

# query: { "time.gteq" => "invalid date", "time.lteq" => "invalid date" }
# => query: {
#   "time.gteq" => nil,
#   "time.lteq" => nil,
# }

# query: { "time.gteq" => "2018-10-01", "time.lteq" => "2018-10-01" }
# => query: {
#   "time.gteq" => Date.parse("2018-10-01 00:00:00"),
#   "time.lteq" => Date.parse("2018-10-01 23:59:59"),
# }
```

#### search condition

- not empty

```ruby
search.query do |q|
  q.search "name.cont", &q.not_empty
end

# query: { "name.cont" => "" }
# => query: {
# }

# query: { "name.cont" => "search" }
# => query: {
#   "name.cont": "search",
# }
```

- not nil

```ruby
search.query do |q|
  q.search "name.cont", &q.not_nil
end

# query: { "name.cont" => nil }
# => query: {
# }

# query: { "name.cont" => "search" }
# => query: {
#   "name.cont": "search",
# }
```

- not all empty

```ruby
search.query do |q|
  q.search "name.in", &q.not_all_empty
end

# query: { "name.in" => [""] }
# => query: {
# }

# query: { "name.in" => ["value1","value2"] }
# => query: {
#   "name.in": ["value1","value2"],
# }
```

- check by block

```ruby
search.query do |q|
  q.search("value.eq"){|val| ["value1","value2"].include? val }
end

# query: { "value.eq" => "value3" }
# => query: {
# }

# query: { "value.eq" => "value1" }
# => query: {
#   "value.eq": "value1",
# }
```


## Install

Add this line to your application's Gemfile:

```ruby
gem 'getto-params'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install getto-params
```


<a id="License"></a>
## License

getto/params is licensed under the [MIT](LICENSE) license.

Copyright &copy; since 2018 shun@getto.systems
