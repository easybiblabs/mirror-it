require 'pty'
require 'expect'
require 'English'
require 'date'

ymd = DateTime.now.strftime('%F')
repos = ''

class Mirror
  def initialize(quiet = true, debug = false)
    @debug = debug
    @quiet = quiet
    @aptly = 'aptly'
  end

  def aptly(cmd)
    call("#{@aptly} #{cmd}")
  end

  def call(cmd)
    output = `#{cmd} 2>&1`
    puts output if @debug
    $CHILD_STATUS.exitstatus
  end

  def run(repositories, _mirror_name, s3_apt_mirror, signing_pass)
    ymd = DateTime.now.strftime('%F')
    repos = ''

    repositories.each do |repo|
      status = aptly("mirror show #{repo['name']}")

      if status == 0
        puts "mirror #{repo['name']} already exists" unless @quiet
      else
        # no such mirror
        # import gpg key
        if repo.key?('key')
          call("gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo['key']}")
        end
        # create mirror
        if repo.key?('ppa')
          aptly("-architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['ppa']}")
        else
          aptly("-architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['archive']} #{repo['dist']}")
        end
      end

      aptly("mirror update #{repo['name']}")

      snapshot = "snap-#{repo['name']}-#{ymd}"

      status = aptly("snapshot show #{snapshot} >/dev/null")

      if status == 0
        puts "snapshot #{snapshot} already exists, skipping" unless @quiet
      else
        aptly("snapshot create #{snapshot} from mirror #{repo['name']}")
      end
      repos += ' ' + snapshot
    end

    packages = "packages-#{ymd}"
    status = aptly("snapshot show #{packages}")

    if status == 0
      puts "merged snapshot #{packages} already exists" unless @quiet
    else
      aptly("snapshot merge #{packages} #{repos}")
    end

    status = aptly("publish list |grep #{s3_apt_mirror}")

    if status == 0
      puts 'switching merged snapshot to todays packages' unless @quiet
      # published snapshot exists, just update
      aptly("publish switch -passphrase='#{signing_pass}' trusty #{s3_apt_mirror} #{packages} 2>&1")
    else
      puts 'publishing snapshot'
      aptly("publish snapshot -passphrase='#{signing_pass}' -distribution='trusty' #{packages} #{s3_apt_mirror} 2>&1")
    end

    oldsnaps = `#{@aptly} snapshot list|tail -n +2|head -n -2|grep -v #{ymd}`
    oldsnaps.scan(/ \* \[([0-9a-z-]+)\]/).each do |line|
      aptly("snapshot drop #{line.first}")
    end
    aptly('db cleanup')
  end
end
