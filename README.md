# monban-params

[rubygems: monban-params](https://rubygems.org/gems/monban-params)

Validate parameters like strong-parameters(rails)

```ruby
require "monban/params"

Monban::Params.new.validate(params) do |v|
  v.hash(
    "name"   => v.combine([v.string, v.not_empty]),
    "token"  => v.combine([v.string, v.allow_empty(v.length(5))]),
    "int"    => v.integer,
    "bool"   => v.bool,
    "key"    => v.equal("KEY"),
    "string" => v.in(["param1","param2"]),
    "tel"    => v.combine([v.string, v.match(%r{\A[0-9]+([0-9-]*)\Z})]),
    "date"   => v.combine([v.string, v.match_date]),
    "number" => v.combine([v.string, v.match_integer]),
    "bool"   => v.combine([v.string, v.match_bool]),
    "data"   => v.not_nil,
    "hash"   => v.hash_strict(
      "array" => v.array(v.string),
      "keys"  => v.array_include(["key1","key2","key3"]),
    ),
  )
end
# => raise Monban::Params::Error if validation failed
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
require "monban/params"

Monban::Params.new.validate(params) do |v|
  # argument `params` should be hash
  v.hash(
    # "key" should be String
    "key" => v.string,

    # "key" should be Integer
    "key" => v.integer,

    # "key" should be Boolean
    "key" => v.bool,


    # "key" should not be empty
    "key" => v.not_empty,

    # validate not_nil
    "key" => v.not_nil,


    # "key" should be equal to "value"
    "key" => v.equal("value"),

    # "key" should be equal to "value1" or "value2"
    "key" => v.in(["value1","value2"]),

    # "key" length should be 10,
    "key" => v.length(10),


    # "key" should match %r{example}
    "key" => v.match(%r{example}),

    # "key" should match integer (value is string, but seem to be a Integer)
    "key" => v.match_integer,

    # "key" downcase should be equal to "true" or "false"
    "key" => v.match_bool,

    # "key" should match date
    "key" => v.match_date,


    # "key" should be hash includes :key that value should be string
    "key" => v.hash(
      key: v.string,
    ),

    # "key" should be hash only includes :key that value should be string
    "key" => v.hash_strict(
      key: v.string,
    ),


    # "key" should be array that has string value
    "key" => v.array(v.string),

    # "key" should be array that has "value1" or "value2"
    "key" => v.array_include(["value1","value2"])


    # "key" should be match integer if value is not empty
    "key" => v.allow_empty(v.match_integer),

    # "key" validate string and not_empty
    "key" => v.combine([v.string, v.not_empty]),
  )
end
# => raise Monban::Params::Error if validation failed
```


## Install

Add this line to your application's Gemfile:

```ruby
gem 'monban-params'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install monban-params
```


<a id="License"></a>
## License

monban/params is licensed under the [MIT](LICENSE) license.

Copyright &copy; since 2018 shun@getto.systems
