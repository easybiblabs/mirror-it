#!/usr/local/bin/ruby
require "pty"
require "expect"

repositories = [
  {
    "name" => "easybib-php55",
    "archive" => "http://ppa.launchpad.net/easybib/php55/ubuntu",
    "dist" => "trusty",
    "key" => "66E3A9B7"
  },
  {
    "name" => "chrislea-noderemote",
    "archive" => "http://ppa.launchpad.net/easybib/remote-mirrors/ubuntu",
    "dist" => "trusty"
  },
  {
    "name" => "chrislea-nodedev",
    "archive" => "http://ppa.launchpad.net/chris-lea/node.js-devel/ubuntu",
    "dist" => "trusty",
    "key" => "C7917B12"
  },
  {
    "name" => "chrislea-redis",
    "archive" => "http://ppa.launchpad.net/chris-lea/redis-server/ubuntu",
    "dist" => "trusty"
  },
  {
    "name" => "nijel-phpmyadmin",
    "archive" => "http://ppa.launchpad.net/nijel/phpmyadmin/ubuntu",
    "dist" => "trusty",
    "key" => "06ED541C"
  },
  {
    "name" => "brightbox-ruby",
    "archive" => "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu",
    "dist" => "trusty",
    "key" => "C3173AA6"
  },
  {
    "name" => "hhvm",
    "archive" => "http://dl.hhvm.com/ubuntu",
    "dist" => "trusty",
    "key" => "1BE7A449"
  },
  {
    "name" => "percona",
    "archive" => "http://repo.percona.com/apt",
    "dist" => "trusty",
    "key" => "CD2EFD2A"
  }
]

mirror_name = ENV['MIRROR_NAME']

# import all keys
repositories.each { |repo|
  next unless repo.has_key?("key")
  system "gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo['key']}"
}

# create mirror
repositories.each { |repo|
  if repo.has_key?("ppa")
    system "aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['ppa']}"
  else
    system "aptly -architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['archive']} #{repo['dist']}"
  end
}

# update local copy
repositories.each { |repo|
  system "aptly mirror update #{repo['name']}"
}

system "aptly repo show #{mirror_name}"

if $?.exitstatus == 0
  puts "#{mirror_name} exists, updating"
  PTY.spawn("aptly publish update trusty #{ENV['S3_APT_MIRROR']}") { | stdin, stdout, pid |
    begin
     stdin.expect(/Enter passphrase:/)
     stdout.write("#{ENV['SIGNING_PASS']}\n")
     stdin.expect(/Enter passphrase:/)
     stdout.write("#{ENV['SIGNING_PASS']}\n")
    rescue Errno::EIO
    end
  }
else
  puts "initializing #{mirror_name}"
  system "aptly repo create #{mirror_name}"

  # import into local mirror
  repositories.each { |repo|
    system "aptly repo import #{repo['name']} #{mirror_name} \"Name (~ .*)\""
  }
  PTY.spawn("aptly -distribution=trusty publish repo #{mirror_name} #{ENV['S3_APT_MIRROR']}") { | stdin, stdout, pid |
    begin
     stdin.expect(/Enter passphrase:/)
     stdout.write("#{ENV['SIGNING_PASS']}\n")
     stdin.expect(/Enter passphrase:/)
     stdout.write("#{ENV['SIGNING_PASS']}\n")
    rescue Errno::EIO
    end
  }
end
