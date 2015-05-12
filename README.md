Heiðrún (`heidrun`)
=======

[![Build Status](https://travis-ci.org/dpla/heidrun.svg?branch=develop)](https://travis-ci.org/dpla/heidrun) [![Code Climate](https://codeclimate.com/github/dpla/heidrun/badges/gpa.svg)](https://codeclimate.com/github/dpla/heidrun) [![Test Coverage](https://codeclimate.com/github/dpla/heidrun/badges/coverage.svg)](https://codeclimate.com/github/dpla/heidrun)

Heiðrún is the DPLA metadata ingestion and QA system, and is an implementation of the [Kri-kri](https://github.com/dpla/KriKri) Rails engine.

<a href="https://commons.wikimedia.org/wiki/File:Manuscript_Heidrun.jpg"><img alt="Heidrun, Icelandic Manuscript, SÁM 66, Árni Magnússon Institute for Icelandic Studies" src="https://upload.wikimedia.org/wikipedia/commons/e/eb/Manuscript_Heidrun.jpg" width="250"/></a>

[More information](https://digitalpubliclibraryofamerica.atlassian.net/wiki/display/TECH/Heidrun) about Heidrun and Kri-kri can be found on [DPLA's Technology Team site](https://digitalpubliclibraryofamerica.atlassian.net/wiki/display/TECH).

Installation
------------

Run these commands:

    bundle install
    bundle exec rake db:migrate



Using Vagrant for Development
-----------------------------

Prerequisites:

* [VirtualBox](https://www.virtualbox.org/) (Version 4.3)
* [Vagrant](http://www.vagrantup.com/) (Version 1.6)
* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest/) (`vagrant plugin install vagrant-vbguest`)
* [Ansible](http://www.ansible.com/) (Version 1.7 or greater; [installation instructions](http://docs.ansible.com/intro_installation.html))


Add this line to your `/etc/hosts` or equivalent:

    192.168.50.21   heidrun

Then do this:

    $ cd /path/to/this/directory
    $ vagrant up
    $ vagrant reload  # Because of o/s packages having been upgraded
    $ vagrant ssh
    $ cd /vagrant
    $ bundle exec rake jetty:start
    $ bundle exec rake db:migrate
    $ bundle exec rails s

You should be able to browse to `http://heidrun:3000/` to see the application.

You may re-run the provisioning with `vagrant provision`.

To run tests, make sure jetty is not already running, and then run `rake ci`:

    $ bundle exec rake jetty:stop
    $ bundle exec rake ci

Please see [the notes in our automation project README](https://github.com/dpla/automation/blob/develop/README-ingestion2.md#when-to-use-this-and-other-dpla-project-vms)
regarding the use of this VM.


About the name
--------------

In Norse mythology, Heiðrún is the goat that consumes leaves from the tree
Læraðr and produces mead for the einherjar.

Contribution Guidelines
-----------------------
Please observe the following guidelines:

  - Write tests for your contributions.
  - Document methods you add using YARD annotations.
  - Use well formed commit messages.

Copyright & License
--------------------

  - Copyright Digital Public Library of America, 2014-2015
  - License: MIT