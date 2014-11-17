#!/usr/local/bin/ruby
require 'pty'
require 'expect'
require 'English'
require 'date'

debug = false

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
  output = `aptly mirror show #{repo['name']}`
  puts output if debug

  if $CHILD_STATUS.exitstatus == 0
    puts "mirror #{repo['name']} already exists"
  else
    # no such mirror
    # import gpg key
    if repo.key?('key')
      output = `gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo['key']}`
      puts output if debug
    end
    # create mirror
    if repo.key?('ppa')
      output = `aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['ppa']}`
      puts output if debug
    else
      output = `aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['archive']} #{repo['dist']}`
      puts output if debug
    end
  end

  output = `aptly mirror update #{repo['name']}`
  puts output if debug

  snapshot = "snap-#{repo['name']}-#{ymd}"

  output = `aptly snapshot show #{snapshot} >/dev/null`
  puts output if debug

  if $CHILD_STATUS.exitstatus == 0
    puts "snapshot #{snapshot} already exists, skipping"
  else
    output = `aptly snapshot create #{snapshot} from mirror #{repo['name']}`
    puts output if debug
  end
  repos += ' ' + snapshot
end

output = `aptly snapshot show packages-#{ymd}`
puts output if debug

if $CHILD_STATUS.exitstatus == 0
  puts "merged snapshot packages-#{ymd} already exists"
else
  output = `aptly snapshot merge packages-#{ymd} #{repos}`
  puts output if debug

end

output = `aptly publish list |grep #{mirror_name}`
puts output if debug

if $CHILD_STATUS.exitstatus == 0
  puts 'switching merged snapshot to todays packages'
  # published snapshot exists, just update
  output = `aptly publish switch -passphrase='#{ENV['SIGNING_PASS']}' trusty #{ENV['S3_APT_MIRROR']}  packages-#{ymd}`
  puts output if debug

else
  puts 'publishing snapshot'
  output = `aptly publish snapshot -passphrase='#{ENV['SIGNING_PASS']}' -distribution='trusty' packages-#{ymd} #{ENV['S3_APT_MIRROR']}`
  puts output if debug

end

# repositories.each do |repo|
#  snapshot="snap-#{repo['name']}-#{ymd}"
#  output = `aptly snapshot drop -force #{snapshot}`
puts output if debug

# end
# FIXME: ERROR: unable to drop: snapshot is published
# We should drop all but current
# output = `aptly snapshot drop -force packages-#{ymd}`
puts output if debug

output = `aptly db cleanup`
puts output if debug
