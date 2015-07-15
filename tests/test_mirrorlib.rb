require 'test/unit'

require File.join(File.dirname(__FILE__), '../lib', 'mirror.rb')

class TestLibMirror < Test::Unit::TestCase
  def test_generate_merged_mirror_list
    repo = [
      {
        'name' => 'first-repo',
        'target' => 'r1'
      },
      {
        'name' => 'second-repo',
        'target' => 'r2'
      },
      {
        'name' => 'merge-repo-1',
        'target' => 'm1'
      },
      {
        'name' => 'merge-repo-2',
        'target' => 'm1'
      }]
    result = Mirror.new.generate_merged_mirror_list(repo)

    assert_equal(
      {
        'r1' => ['first-repo'], 'r2' => ['second-repo'],
        'm1' => ['merge-repo-1', 'merge-repo-2']
      },
      result
    )
  end
end
