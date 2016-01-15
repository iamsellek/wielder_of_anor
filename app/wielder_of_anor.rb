require_relative 'wielder_of_anor_helper'

helper = WielderOfAnorHelper.new(ARGV[0], ARGV[1], Dir.pwd)

helper.search_for_forbidden_words