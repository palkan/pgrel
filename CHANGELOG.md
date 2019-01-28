# Change log

## master

## 0.3.0 (2019-26-01)

- Rename `#value` method to `#overlap_values`.
- Rename `#values` method to `#contains_values`.
- Improve `#contains_values` method:
	eliminate multiple `avals` calls for Hstore and multiple `array_agg` calls for Jsonb.

  See https://github.com/palkan/pgrel/pull/9. ([@StanisLove][])

## 0.2.0 (2018-06-15)

- Add `#update_store` methods. ([@StanisLove][])

  See https://github.com/palkan/pgrel/pull/5.

[@palkan]: https://github.com/palkan
[@StanisLove]: https://github.com/StanisLove
