require_relative "wielder_of_anor_helper"

helper = WielderOfAnorHelper.new

helper.help if ARGV[0] == "help"

helper.first_run if ARGV[0] == "config"

helper.prepare(ARGV[0], ARGV[1])

helper.wielder_of_anor
