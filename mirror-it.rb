#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pty'
require 'expect'
require 'English'
require 'date'
require 'lib/mirror'

debug = false
quiet = true

repositories = [
  {
    'name' => 'easybib-php56',
    'archive' => 'http://ppa.launchpad.net/easybib/php56/ubuntu',
    'dist' => 'trusty',
    'key' => '66E3A9B7',
    'target' => 'php56'
  },
  {
    'name' => 'easybib-php55',
    'archive' => 'http://ppa.launchpad.net/easybib/php55/ubuntu',
    'dist' => 'trusty',
    'key' => '66E3A9B7',
    'target' => 'php55'
  },
  {
    'name' => 'chrislea-noderemote',
    'archive' => 'http://ppa.launchpad.net/easybib/remote-mirrors/ubuntu',
    'dist' => 'trusty',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'chrislea-nodedev',
    'archive' => 'http://ppa.launchpad.net/chris-lea/node.js-devel/ubuntu',
    'dist' => 'trusty',
    'key' => 'C7917B12',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'chrislea-redis',
    'archive' => 'http://ppa.launchpad.net/chris-lea/redis-server/ubuntu',
    'dist' => 'trusty',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'nijel-phpmyadmin',
    'archive' => 'http://ppa.launchpad.net/nijel/phpmyadmin/ubuntu',
    'dist' => 'trusty',
    'key' => '06ED541C',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'brightbox-ruby',
    'archive' => 'http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu',
    'dist' => 'trusty',
    'key' => 'C3173AA6',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'hhvm',
    'archive' => 'http://dl.hhvm.com/ubuntu',
    'dist' => 'trusty',
    'key' => '1BE7A449',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'qafoo',
    'archive' => 'https://s3-eu-west-1.amazonaws.com/qafoo-profiler/packages',
    'dist' => 'debian',
    'key' => 'EEB5E8F4',
    'target' => 'remote-mirrors'
  },
  {
    'name' => 'apache-couch-stable',
    'archive' => 'http://ppa.launchpad.net/couchdb/stable/ubuntu',
    'dist' => 'trusty',
    'key' => 'C17EAB57',
    'target' => 'remote-mirrors'
  }
]

mirror = Mirror.new(quiet, debug)
mirror.run(repositories, ENV['S3_APT_MIRROR'], ENV['SIGNING_PASS'])
