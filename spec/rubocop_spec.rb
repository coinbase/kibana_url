# frozen_string_literal: true

require 'open3'

RUBOCOP_COMMAND = 'bundle exec rubocop --color'

describe 'rubocop' do
  it 'should ensure that we have linted code' do
    stdout, stderr, exit_status = Open3.capture3(RUBOCOP_COMMAND)
    unless exit_status.success?
      puts "Rubocop linting failed. Run $ #{RUBOCOP_COMMAND} to check."
      puts "Stdout:\n#{stdout}"
      puts "Stderr:\n#{stderr}"
    end
    expect(exit_status.success?).to eq(true)
  end
end
