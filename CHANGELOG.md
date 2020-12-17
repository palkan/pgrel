# Change log

## master

- Update internal query building for Rails 6.1 compatibility. ([@zokioki][])

## 0.3.0 (2019-28-01)

- Rename `#value` method to `#overlap_values`.
- Rename `#values` method to `#contains_values`.
- Improve `#contains_values` method:
	eliminate multiple `avals` calls for Hstore and multiple `array_agg` calls for Jsonb.

  See https://github.com/palkan/pgrel/pull/9. ([@StanisLove][])

- Quote store name in queries. ([@palkan][])

  Previously, we didn't quote store name in queries which could led
  to ambiguity conflicts when joining tables.
  Now it fixed.

## 0.2.0 (2018-06-15)

- Add `#update_store` methods. ([@StanisLove][])

  See https://github.com/palkan/pgrel/pull/5.

[@palkan]: https://github.com/palkan
[@StanisLove]: https://github.com/StanisLove
