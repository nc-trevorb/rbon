## Rbon: RuBy Object Notation

### About
A tool for deriving a json-schema (draft v4) from a collection of jsons.

### Usage
#### Start a repl
Run `./bin/repl`.

#### Validate json against a schema
Edit the files in `./data/validation/` and run `Rbon.run_validation` from the repl.

#### Logging jsons
Run `Rbon.log_json(json)`.  By default, this will log it to `./log/rbon/jsons` in
the current project.

#### Logging jsons to specific location
The logging destination can be overwritten by setting the `path` keyword arg:
`Rbon.log_json(json, path: 'path/to/something')`.  This is useful for e.g. logging App
Server responses into the Rbon project so they can be aggregated.  You would need a line
like `Rbon.log_json(response, path: '~/code/rbon/data/aggregation/in/#{name})` in
an App Server controller.

#### Aggregating jsons into a schema
After putting some json files in `./data/aggregation/in/#{name}`, run `Rbon.aggregate(name)`
from the repl.

#### Recording schemas
`Rbon.aggregate(name)` will return the aggregated schema - to write that schema to a file,
you can set the `write` keyword arg: `Rbon.aggregate(name, write: true)`.  They will be
written to `./data/aggregation/out/#{name}`.

#### Overwriting jsons
When recording a schema, an error is raised if the name is already being used.  To replace the old
aggregated schema, you can set the `overwrite` keyword arg: `Rbon.aggregate(name, write:
true, overwrite: true)`.  If you set the `overwrite` keyword arg, the `write` keyword arg doesn't
make a difference, so you can just use `Rbon.aggregate(name, overwrite: true)`.

