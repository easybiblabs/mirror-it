#!/usr/local/bin/ruby
require 'pty'
require 'expect'
require 'English'
require 'date'

repositories = [
  {
    'name' => 'easybib-php55',
    'archive' => 'http://ppa.launchpad.net/easybib/php55/ubuntu',
    'dist' => 'trusty',
    'key' => '66E3A9B7'
  },
  {
    'name' => 'chrislea-noderemote',
    'archive' => 'http://ppa.launchpad.net/easybib/remote-mirrors/ubuntu',
    'dist' => 'trusty'
  },
  {
    'name' => 'chrislea-nodedev',
    'archive' => 'http://ppa.launchpad.net/chris-lea/node.js-devel/ubuntu',
    'dist' => 'trusty',
    'key' => 'C7917B12'
  },
  {
    'name' => 'chrislea-redis',
    'archive' => 'http://ppa.launchpad.net/chris-lea/redis-server/ubuntu',
    'dist' => 'trusty'
  },
  {
    'name' => 'nijel-phpmyadmin',
    'archive' => 'http://ppa.launchpad.net/nijel/phpmyadmin/ubuntu',
    'dist' => 'trusty',
    'key' => '06ED541C'
  },
  {
    'name' => 'brightbox-ruby',
    'archive' => 'http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu',
    'dist' => 'trusty',
    'key' => 'C3173AA6'
  },
  {
    'name' => 'hhvm',
    'archive' => 'http://dl.hhvm.com/ubuntu',
    'dist' => 'trusty',
    'key' => '1BE7A449'
  },
  {
    'name' => 'qafoo',
    'archive' => 'https://s3-eu-west-1.amazonaws.com/qafoo-profiler/packages',
    'dist' => 'debian',
    'key' => 'EEB5E8F4'
  }
]

mirror_name = ENV['MIRROR_NAME']

ymd = DateTime.now.strftime('%F')
repos = ''

repositories.each do |repo|
  system "aptly repo show #{mirror_name}"
  unless $CHILD_STATUS.exitstatus == 0
    # no such mirror
    # import gpg key
    if repo.key?('key')
     system "gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo['key']}"
    end
    # create mirror
    if repo.key?('ppa')
      system "aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['ppa']}"
    else
      system "aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['archive']} #{repo['dist']}"
    end
  end

  system "aptly mirror update #{repo['name']}"
  snapshot="snap-#{repo['name']}-#{ymd}"
  
  system "aptly snapshot create #{snapshot} from mirror #{repo['name']}"
  repos += ' ' + snapshot
end

system "aptly snapshot merge packages-#{ymd} #{repos}"

system " aptly publish list |grep #{mirror_name}"
if $CHILD_STATUS.exitstatus == 0
  # published snapshot exists, just update
  system "aptly publish switch -passphrase='#{ENV['SIGNING_PASS']}' trusty #{ENV['S3_APT_MIRROR']}  packages-#{ymd}"
else
  system "aptly publish snapshot -passphrase='#{ENV['SIGNING_PASS']}' -distribution='trusty' packages-#{ymd} #{ENV['S3_APT_MIRROR']}"
end

#repositories.each do |repo|
#  snapshot="snap-#{repo['name']}-#{ymd}"
#  system "aptly snapshot drop -force #{snapshot}"
#end
# FIXME ERROR: unable to drop: snapshot is published
# We should drop all but current
#system "aptly snapshot drop -force packages-#{ymd}"

system "aptly db cleanup"
