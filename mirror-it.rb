#!/usr/local/bin/ruby

repositories = [
  {
    "name" => "easybib-php55",
    "ppa" => "ppa:easybib/php55",
    "key" => "66E3A9B7"
  },
  {
    "name" => "dotcloud-docker",
    "ppa" => "ppa:dotcloud/lxc-docker",
    "key" => "63561DC6"
  },
  {
    "name" => "mapnik-boost",
    "ppa" => "ppa:mapnik/boost",
    "key" => "5D50B6BA"
  },
  {
    "name" => "chrislea-noderemote",
    "ppa" => "ppa:easybib/remote-mirrors",
  },
  {
    "name" => "chrislea-nodedev",
    "ppa" => "ppa:chris-lea/node.js-devel",
    "key" => "C7917B12"
  },
  {
    "name" => "chrislea-redis",
    "ppa" => "ppa:chris-lea/redis-server"
  },
  {
    "name" => "nijel-phpmyadmin",
    "ppa" => "ppa:nijel/phpmyadmin",
    "key" => "06ED541C"
  },
  {
    "name" => "brightbox-ruby",
    "ppa" => "ppa:brightbox/ruby-ng",
    "key" => "C3173AA6"
  }
]

mirror_name = ENV['MIRROR_NAME']

# import all keys
repositories.each { |repo|
  next if !repo.key
  system "gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo.key}"
}

# create mirror
repositories.each { |repo|
  system "aptly -architectures=\"amd64,i386\" -ignore-signatures=true  mirror create #{repo.name} #{repo.ppa}"
}

# update local copy
repositories.each { |repo|
  system "aptly mirror update #{repo.name}"
}

system "aptly repo create #{mirror_name}"

# import into local mirror
repositories.each { |repo|
  system "aptly repo import #{repo.name} #{mirror_name} \"Name (~ .*)\""
}

#FIXME skip-signing sucks
system "aptly -skip-signing -distribution=precise publish repo #{mirror_name} #{ENV['S3_APT_MIRROR']}"
