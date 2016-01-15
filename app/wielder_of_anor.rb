require_relative 'wielder_of_anor_helper'

helper = WielderOfAnorHelper.new(ARGV[0], ARGV[1], Dir.pwd)

# Run the git diff and export the results into docs/files_changed
helper.search_for_forbidden_words