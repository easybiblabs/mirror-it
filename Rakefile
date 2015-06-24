#!/usr/bin/env rake
# encoding: utf-8

require 'bundler'
require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'yaml'

Bundler.setup

task default: [
  :test,
  :rubocop
]

desc 'Run tests'
Rake::TestTask.new do |t|
  t.pattern = '**/**/tests/test_*.rb'
end

require 'rubocop/rake_task'
# no autocorrect in travis
if ENV['TRAVIS']
  RuboCop::RakeTask.new
else
  RuboCop::RakeTask.new do |task|
    task.options = ['--auto-correct']
  end
end
