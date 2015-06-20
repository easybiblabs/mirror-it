require 'pty'
require 'expect'
require 'English'
require 'date'

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

  def run(repositories, mirror_uri_prefix, password)
    @ymd = DateTime.now.strftime('%F')

    update_snapshots(repositories)

    merged_mirrors = generate_merged_mirror_list(repositories)

    update_merged_mirrors(merged_mirrors, mirror_uri_prefix, password)

    remove_old_snapshots
  end

  def update_merged_mirrors(merged_mirrors, mirror_uri_prefix, password)
    merged_mirrors.each do |merged_mirror, repositories|
      repos = repositories.join(' ')
      mirror_uri = mirror_uri_prefix + '-' + merged_mirror
      merged_snapshot_name = merged_mirror + '-' + @ymd

      create_merged_snapshot(merged_snapshot_name, repos)
      publish_merged_snapshot(merged_mirror, mirror_uri, password)
    end
  end

  def generate_merged_mirror_list(repositories)
    merged_mirrors = {}

    repositories.each do |repo|
      merged_mirrors[repo['target']] = [] if merged_mirrors[repo['target']].nil?
      merged_mirrors[repo['target']].push(repo['name'])
    end

    merged_mirrors
  end

  def update_snapshots(repositories)
    repositories.each do |repo|
      mirror_create(repo) unless mirror_exists?(repo['name'])
      create_snapshot(repo['name'])
    end
  end

  def remove_old_snapshots
    oldsnaps = `#{@aptly} snapshot list|tail -n +2|head -n -2|grep -v #{@ymd}`
    oldsnaps.scan(/ \* \[([0-9a-z-]+)\]/).each do |line|
      aptly("snapshot drop #{line.first}")
    end
    aptly('db cleanup')
  end

  def publish_merged_snapshot(packages, s3_apt_mirror, signing_pass)
    status = aptly("publish list |grep #{s3_apt_mirror}")

    if status == 0
      puts 'switching merged snapshot to todays packages' unless @quiet
      # published snapshot exists, just update
      return aptly("publish switch -passphrase='#{signing_pass}' trusty #{s3_apt_mirror} #{packages} 2>&1")
    end

    puts 'publishing snapshot' unless @quiet
    aptly("publish snapshot -passphrase='#{signing_pass}' -distribution='trusty' #{packages} #{s3_apt_mirror} 2>&1")
  end

  def create_merged_snapshot(name, repos)
    status = aptly("snapshot show #{name}")
    if status == 0
      puts "merged snapshot #{name} already exists" unless @quiet
    else
      aptly("snapshot merge #{name} #{repos}")
    end
  end

  def create_snapshot(repo)
    aptly("mirror update #{repo}")

    snapshot = "snap-#{repo}-#{@ymd}"

    status = aptly("snapshot show #{snapshot} >/dev/null")

    if status == 0
      puts "snapshot #{snapshot} already exists, skipping" unless @quiet
    else
      aptly("snapshot create #{snapshot} from mirror #{repo}")
    end
    snapshot
  end

  def mirror_exists?(name)
    status = aptly("mirror show #{name}")

    if status == 0
      puts "mirror #{name} already exists" unless @quiet
      return true
    end
    false
  end

  def mirror_create(repo)
    # import gpg key
    if repo.key?('key')
      call("gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keys.gnupg.net --recv-keys #{repo['key']}")
    end
    # create mirror
    if repo.key?('ppa')
      status = aptly("-architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['ppa']}")
    else
      status = aptly("-architectures=\"amd64,i386\" mirror create #{repo['name']} #{repo['archive']} #{repo['dist']}")
    end
    (status == 0)
  end
end
