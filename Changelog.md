v0.8.2 - 2016 Oct 17
---
* Pin gems from Krikri to tiny versions

v0.8.1 - 2016 Sep 06
---
* Add LoC Harvester 
* Upgrade to Krikri 0.14
* Update the solr schema with the krikri generator
* Default query for CDL harvester now excludes datasets
* Add krikri-spec gem to introduces the shared examples and matchers
* Pin gems to tiny versions currently running in production

v0.8.0 - 2016 Mar 21
---
* Upgrade to Krikri 0.11 or higher
* Add CdlHarvester 
* Introduce UVA, IA and NYPL harvesters using Krikri::AsyncUriGetter
* Allow net connect after test suite for CodeClimate
* Upgrade Rake & tighten up rake dependency
* Add Smithsonian harvester
* Use bundler 1.11 and add Rubies 2.1.6, 2.2.3, and 2.3.0 in CI
* Parameterize log_level configuration setting
* Add doc comments to HathiHarvester re. file URIs
* Set rbenv global version
* Disable Spring

v0.7.2 - 2016 Jan 22
---
* Add logging and retries for invalid JSON in NARA Harvester

v0.7.1 - 2015 Dec 22
---
* Implement the Hathi harvester
* Relax Rails dependency to the 4.1.x series

v0.7.0 - 2015 Nov 24
---
* Add new file mapping tool
* Upgrade Krikri to 0.10.0

v0.6.0 - 2015 Nov 23
---
* Fix NaraHarvester logging
* Add enrichment for removing "placeholder" values
* Add Heidrun::MappingTools
* Upgrade Krikri to 0.9

v0.5.3 - 2015 Jul 01
---
* Tighten direct gem dependencies; allow Krikri ~> 0.7
	
v0.5.2 - 2015 Jun 24
---
* Upgrade to Krikri 0.7.0 and Rails 4.1.11
* Revert "Bump up sass-rails version to fix deployment error"

v0.5.1 - 2015 Jun 24
---
* Bump up sass-rails version to fix deployment error

v0.5.0 - 2015 Jun 8
---
* Add development VM
* Add NARA harvester
* Bump Krikri version to 0.6.0
* Update Solr files with changes from Krikri 0.6.0

v0.4.9 - 2015 Apr 12
---
* Update to Krikri 0.5.7

v0.4.8 - 2015 Apr 12
---
* Update to Krikri 0.5.6

v0.4.7 - 2015 Apr 12
---
* Update to Krikri 0.5.5

v0.4.6 - 2015 Apr 9
---
* Update to Krikri 0.5.4

v0.4.5 - 2015 Apr 6
---
* Block robots and add some default text at app root
* Update to Krikri 0.5.3

v0.4.3 - 2015 Apr 6
---
* Update to Krikri 0.5.2

v0.4.2 - 2015 Apr 4
---
* Update to Krikri 0.5.1

v0.4.1 - 2015 Apr 3
---
* Note: this release requires running `rake db:migrate` on deployment
* Note: you will need to reindex your data in your Solr index after deployment
* Update to Krikri 0.5.0
* Update to Rails 4.1.10

v0.3.1 - 2015 Mar 10
---
* Add MDL Harvester
* Update to Krikri 0.4.0

v0.3.0 - 2015 Mar 10
---
* Note: this release requires running `rake db:migrate` on deployment
* Update to Krikri 0.3.3

v0.2.2 - 2015 Mar 6
---
* Update to Krikri 0.3.x

v0.2.1 - 2015 Feb 23
---

* Update to krikri 0.2.1
* Allow `require`-ing of vendored mappings to traverse symlinks
* Add vendored mapping structure

v0.1.1 - 2015 Feb 06
---

* Update Krikri to 0.1.3 and Rails to 4.1.9.
* Improve test isolation and scope factory building.
* Provide default Jettywrapper configuration.

v0.1.0 - 2015 Jan 30
---

* Initial public release
