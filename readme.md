## Overview

**AssetDB** is a lightweight Ruby library for managing collections of assets and their inter-dependencies. You can:

* Declare arbitrary asset types (default: `:css`, `:js`)
* Organize assets into **groups** → **packages** → **asset-type lists**
* Define package-to-package dependencies, forming a DAG
* Resolve a package's full dependency tree into a deduplicated, correctly ordered list of assets
* Combine multiple packages into one unioned collection

## Configuration-Driven Setup

```ruby
config = {
	types: ['css', 'js'], # optional; default [:css, :js]
	basepath: '/assets/:type/:group/:package', # optional
	folders: { # optional
		separator: '/' # must specify separator to be able to specify "group/package"
		'features': 'myfeatures', # this group uses a different string in the basepath
		'core/base': nil # this package is collapsed in the basepath
	},
	# Each further key at this level is a group
	features: {
		# Each key at this level is a package
		dropdown: {
			# Asset types within this package
			css: %w[drop.css effect.css],
			js:  %w[foundation.js drop.js]
			# each further key at this level refers to a group
			core: ['base'] # this package depends on the base package in the core group
		}
	},
	core: {
		base: {
			css: 'base.css'
		}
	}
}

db = AssetDB.load(config)
dropdown = db.group('features').package('dropdown')
```

## DSL

```ruby
require 'asset_db'

db = AssetDB.build(asset_types: %i[css js], basepath: '/assets/:type/:group/:package') do |d|
	d.group 'features' do |g|
		g.package 'dropdown' do |p|
			p.asset :css, 'drop.css'
			p.asset :css, 'effect.css'
			p.asset :js,  'foundation.js'
			p.asset :js,  'drop.js'
			p.depends_on 'base', group_id: 'core'
		end
	end

	d.group 'core' do |g|
		g.package 'base' do |p|
			p.asset :css, 'base.css'
		end
	end
end

dropdown = db.group('features').package('dropdown')
css_list = dropdown.resolved_assets(:css)
# => [ base.css, drop.css, effect.css ]
css_list.each do |asset|
	puts db.build_url(asset)
end
```

## URL Building & Folder Overrides

The `basepath` setting lets you define a path string with placeholders `:type`, `:group`, `:package` that will be prepended to any relative asset paths.

  * `:type`: asset type (`css`, `js`, etc.)
  * `:group`: group id or folder
  * `:package`: package id or folder

If `asset.url` is absolute (starts with a protocol), it is returned unchanged.

When defining a group/package you can specify the `folder` string which replaces the placeholder (default is the group/package's id). Setting this to nil/false/empty will collapse that part of the basepath entirely.

## Combining Packages

You can union multiple packages (and their transitive deps) into one collection:

```ruby
base     = db.group('core').package('base')
dropdown = db.group('features').package('dropdown')
combined = dropdown + base

# Iterate all JS assets without duplicates
combined.each_asset(:js).each do |asset|
  puts db.build_url(asset)
end
```

You can also use the `unify` method directly with any number of packages or splat in an array of packages.

```ruby
combined = db.unify(base, dropdown, other)
packages = [base, dropdown, other]
combined = db.unify(*packages)
```

## Development

Run `rspec` to test.

Run `gem build` to build the gem.