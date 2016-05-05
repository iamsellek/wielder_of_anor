require_relative "wielder_of_anor_helper"

WielderOfAnorHelper.help if ARGV[0] == "help"

WielderOfAnorHelper.first_run if ARGV[0] == "config"

helper = WielderOfAnorHelper.new(ARGV[0], ARGV[1])

helper.wielder_of_anor
