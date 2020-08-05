[![Gem Version](https://badge.fury.io/rb/pgrel.svg)](https://rubygems.org/gems/pgrel) [![Build Status](https://travis-ci.org/palkan/pgrel.svg?branch=master)](https://travis-ci.org/palkan/pgrel)

## Pgrel

ActiveRecord extension for querying hstore, array and jsonb.

Compatible with **Rails** >= 4.2 (including **Rails 6**).

#### Install

In your Gemfile:

```ruby
gem "pgrel", "~> 0.3"
```

### HStore

#### Querying

The functionality is based on ActiveRecord `WhereChain`. 
To start querying call `where(:store_name)` and chain it with store-specific call (see below).

Query by key value:

```ruby
Hstore.where.store(:tags, a: 1, b: 2)
#=> select * from hstores where tags @> '"a"=>"1","b"=>"2"'

Hstore.where.store(:tags, a: [1, 2])
#=> select * from hstores where (tags @> '"a"=>"1"' or tags @> '"a"=>"2"')

Hstore.where.store(:tags, :a)
#=> select * from hstores where (tags @> '"a"=>NULL')

Hstore.where.store(:tags, { a: 1 }, { b: 2 })
#=> select * from hstores where (tags @> '"a"=>"1" or tags @> "b"=>"2"')
```

Keys existence:

```ruby
# Retrieve items that have key 'a' in 'tags'::hstore
Hstore.where.store(:tags).key(:a)
#=> select * from hstores where tags ? 'a'

# Retrieve items that have both keys 'a' and 'b' in 'tags'::hstore
Hstore.where.store(:tags).keys('a', 'b')
#=> select * from hstores where tags ?& array['a', 'b']

# Retrieve items that have either key 'a' or 'b' in 'tags'::hstore
Hstore.where.store(:tags).any('a', 'b')
#=> select * from hstores where tags ?| array['a', 'b']
```

Values existence:

```ruby
# Retrieve items that have value '1' OR '2'
Hstore.where.store(:tags).overlap_values(1, 2)
#=> select * from hstores where (avals(tags) && ARRAY['1', '2'])

# Retrieve items that have values '1' AND '2'
Hstore.where.store(:tags).contains_values(1, 2)
#=> select * from hstores where (avals(tags) @> ARRAY['1', '2'])
```

Containment:

```ruby
Hstore.where.store(:tags).contains(a: 1, b: 2)
#=> select * from hstores where tags @> '\"a\"=>\"1\", \"b\"=>\"2\"'

Hstore.where.store(:tags).contained(a: 1, b: 2)
#=> select * from hstores where tags <@ '\"a\"=>\"1\", \"b\"=>\"2\"'
```

#### Update

Is implemented through `ActiveRecord::Store::FlexibleHstore` and `ActiveRecord::Store::FlexibleJsonb`
objects. You can get them by sending `update_store(store_name)` to relation or class.

Add key, value pairs:

```ruby
Hstore.update_store(:tags).merge(new_key: 1, one_more: 2)
Hstore.update_store(:tags).merge([[:new_key, 1], [:one_more, 2]])
```

Delete keys:

```ruby
Hstore.update_store(:tags).delete_keys(:a, :b)
```

Delete key, value pairs:

```ruby
Hstore.update_store(:tags).delete_pairs(a: 1, b: 2)
```

### JSONB

All queries and updates for Hstore also available for JSONB.

**NOTE**. Querying by array value always resolves to `(... or ...)` statement. 
Thus it's impossible to query json array value, e.g.:

```ruby
Model.create!(tags: {main: ['a', 'b']})

Model.where.store(:tags, main: ['a', 'b']).empty? == true
#=> select * from models where  (tags @> '{\"main\":\"a\"}' or tags @> '{\"main\":\"b\"}')
```

Path query:

```ruby
Model.create!(tags: {main: ['a', 'b'], user: { name: 'john' } })

# You can use object to query by simple value
Model.where.store(:tags).path(user: { name: 'john' })
#=> select * from hstores where tags#>>'{\"user\",\"name\"}' = 'john'
# or passing path parts as args one by one with value at the end
Model.where.store(:tags).path(:user, :name, 'john')

# Match by complex value (array or object)
Model.where.store(:tags).path(:main, ['a', 'b'])
#=> select * from hstores where tags#>'{\"main\"}' = '[\"a\",\"b\"]'
```

### Array

Array stores support containment queries (just like Hstore and JSONB) and also `overlap` operator.

**NOTE**. There are some other array operators ('ANY', 'ALL', querying by index - value) which I'm not going to implement – PRs are welcomed!

Overlap:
```ruby
Model.where.store(:tags).overlap('a', 'b')
#=> select * from hstores where tags && '{\"a\",\"b\"}'
```

### Negation

Use `not` before operator to constuct negation or pass arguments to `not` to run key-value query.

```ruby
Model.where.store(:tags).not.overlap('a', 'b')
#=> select * from hstores where not (tags && '{\"a\",\"b\"}')

Hstore.where.store(:tags).not(a: 1)
#=> select * from hstores where tags->'a' != '1'
```

