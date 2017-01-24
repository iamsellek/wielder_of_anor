require 'shellwords'
require 'yaml'
require 'fileutils'
require 'rainbow'

require_relative 'wielder_of_anor/version'

module WielderOfAnor
  class WielderOfAnor
    include WielderOfAnorVersion

    def initialize
      set_app_directory

      @forbidden_words = []
    end

    ##############################################################################
    ##############################################################################
    ##                                                                          ##
    ## commit_message is the git commit message the user would like to send     ##
    ## once we have verified that there are no forbidden words present in their ##
    ## code.                                                                    ##
    ##                                                                          ##
    ## force_commit is either '1' or nil. If it's 1, we will commit later even  ##
    ## if there are forbidden words present.                                    ##
    ##                                                                          ##
    ##############################################################################
    ##############################################################################

    def prepare(commit_message, force_commit)
      # If there's just one, it's the current version. Don't run if the current config is present.
      restore_woa_settings if Dir.glob("#{@app_directory.chomp("/wielder_of_anor-#{VERSION}")}/wielder_of_anor*").length > 1 &&
                              !(File.exists?("#{@app_directory}/lib/config.yaml"))
      first_run unless File.exists?("#{@app_directory}/lib/config.yaml")

      config = YAML.load_file("#{@app_directory}/lib/config.yaml")
      @commit_message = commit_message
      @force_commit = force_commit
      @current_directory = Dir.pwd
      @files_changed_file_location = config['files_changed_file_location']
      @commit_for_user = config['commit_for_user']
      @check_branch = config['check_branch']
      @branches_to_check = config['branches_to_check']
      @current_branch_file_location = "#{@app_directory}/lib/current_branch"

      # Don't want to use a previous version.
      File.delete(@files_changed_file_location) if File.exists?(@files_changed_file_location)

      git_diff

      @files_changed_file = File.open(@files_changed_file_location, "r")
      @forbidden_words = config['forbidden_words']
    end

    def help
      lines_pretty_print 'Wielder of Anor can accept up to two parameters on run. The first parameter can be:'

      single_space

      lines_pretty_print '- Your eventual commit message (in quotes). This is ignored if you have not allowed '\
           'Wielder of Anor to commit for you.'
      lines_pretty_print '- help - You should already know what this does :).'
      lines_pretty_print '- config - Re-runs the initial set up.'

      single_space

      lines_pretty_print 'And your second parameter can only be \'1\', and it\'ll be ignored unless all of the '\
                         'following is true:'

      single_space

      lines_pretty_print '- You have allowed Wielder of Anor to run commits for you.'
      lines_pretty_print '- Your first parameter is your commit message.'

      abort
    end

    def output_forbidden_words
      set_app_directory
      config = YAML.load_file("#{@app_directory}/lib/config.yaml")

      unless config && config['forbidden_words']
        lines_pretty_print Rainbow('You have yet to set your forbidden words! Please run the app with the parameter '\
                                   '\'config\' to set up your configurations and forbidden words.').red

        abort
      end

      lines_pretty_print Rainbow('Your forbidden words are:').yellow

      single_space

      config['forbidden_words'].each do |word|
        lines_pretty_print Rainbow(word).yellow
      end

      single_space

      abort
    end

    def first_run
      lines_pretty_print 'Thanks for downloading Wielder of Anor! Let\'s run through the '\
           'initial setup!'

      STDIN.gets

      files_changed_file_location = "#{@app_directory}/lib/files_changed"

      commit_for_user = set_commit_for_user

      check_branch = set_check_branch

      branches_to_check = set_branches_to_check if check_branch == 'yes' || check_branch == 'y'

      single_space

      forbidden_words = set_forbidden_words

      set_configs(files_changed_file_location, forbidden_words, commit_for_user, check_branch, branches_to_check)
    end

    def set_commit_for_user
      lines_pretty_print 'Would you like Wielder of Anor to run your commits for you once you'\
           ' have verified that your code is free of forbidden words?'
      lines_pretty_print Rainbow('(Type \'yes\' or \'no\'. Just hitting enter defaults to no.)').yellow

      commit_for_user = STDIN.gets.strip!.downcase
      commit_for_user = 'no' if commit_for_user == ''

      until commit_for_user == 'yes' || commit_for_user =='y' || commit_for_user == 'no' || commit_for_user == 'n' do
        lines_pretty_print Rainbow('Please type either \'yes\' or \'no\'.').yellow
        commit_for_user = STDIN.gets.strip!.downcase
      end

      single_space

      commit_for_user
    end

    def set_check_branch
      lines_pretty_print 'Would you like Wielder of Anor to stop you from committing to a certain branch or branches?'
      lines_pretty_print Rainbow('(Type \'yes\' or \'no\'. Just hitting enter defaults to no.)').yellow

      check_branch = STDIN.gets.strip!.downcase
      check_branch = 'no' if check_branch == ''

      until check_branch == 'yes' || check_branch =='y' || check_branch == 'no' || check_branch == 'n' do
        lines_pretty_print Rainbow('Please type either \'yes\' or \'no\'.').yellow
        check_branch = STDIN.gets.strip!.downcase
      end

      single_space

      check_branch
    end

    def set_branches_to_check
      branches_to_check = []

      done = false

      lines_pretty_print 'Sounds good! What branches should I block you from committing to?'
      single_space

      until done do
        lines_pretty_print Rainbow('Enter a forbidden branch and hit enter. If you are done entering forbidden '\
                                   'branches, just hit enter instead.').yellow unless branches_to_check.count > 0

        lines_pretty_print Rainbow('Added! Enter another forbidden branch and hit enter. If you are done '\
                                   'entering forbidden branches, just hit enter instead.').yellow unless branches_to_check.count == 0
        branch = STDIN.gets.strip!

        single_space

        if branch == ''
          done = true
        else
          branches_to_check << branch
        end
      end

      branches_to_check
    end

    def set_configs(files_changed_file_location, forbidden_words, commit_for_user, check_branch, branches_to_check)
      config = {}
      config['files_changed_file_location'] = files_changed_file_location

      if commit_for_user == 'yes' || commit_for_user == 'y'
        config['commit_for_user'] = true
      else
        config['commit_for_user'] = false
      end

      if check_branch == 'yes' || check_branch == 'y'
        config['check_branch'] = true
        config['branches_to_check'] = branches_to_check
      else
        config['check_branch'] = false
        config['branches_to_check'] = []
      end

      config['forbidden_words'] = forbidden_words

      file = File.open("#{@app_directory}/lib/config.yaml", 'w')
      YAML.dump(config, file)
      file.close

      lines_pretty_print 'And with that, we\'re done! Feel free to run Wielder of Anor again if'\
           ' you\'d like to check your code now!'

      abort
    end

    def set_forbidden_words
      forbidden_words = []

      done = false

      lines_pretty_print 'Great! Now that we\'re done with that, let\'s add your forbidden '\
                         'words from here!'
      single_space

      until done do
        lines_pretty_print Rainbow('Enter a forbidden word and hit enter. If you are done entering '\
                           'forbidden words just hit enter instead.').yellow unless forbidden_words.count > 0

        lines_pretty_print Rainbow('Added! Enter another forbidden word and hit enter. If you are done '\
                                   'entering forbidden words, just hit enter instead.').yellow unless forbidden_words.count == 0
        word = STDIN.gets.strip!

        single_space

        if word == ''
          done = true
        else
          forbidden_words << word
        end
      end

      forbidden_words
    end

    def git_diff
      bash("git diff HEAD --name-only --staged > #{@files_changed_file_location}")
    end

    def add_forbidden_word(word)
      set_app_directory
      config_yaml = YAML.load_file("#{@app_directory}/lib/config.yaml")
      config_file = File.open("#{@app_directory}/lib/config.yaml", 'w')

      if word.nil?
        lines_pretty_print Rainbow('Please submit your word as a second parameter.').red

        abort
      end

      if config_yaml['forbidden_words'].include?(word)
        lines_pretty_print Rainbow("''#{word}'' is already a forbidden word!").red

        abort
      end

      config_yaml['forbidden_words'] << word

      YAML.dump(config_yaml, config_file)

      lines_pretty_print 'Added!'

      abort
    end

    def wielder_of_anor
      found_forbidden = false
      count = File.foreach(@files_changed_file).inject(0) {|c, line| c+1}

      if count == 0
        single_space

        lines_pretty_print Rainbow('No files have been added. Please use the git add command to add files to your '\
                             'commit.').red

        single_space

        abort
      end

      # If we're forcing the commit, don't bother checking for forbidden words.
      unless @force_commit
        single_space

        print_header_footer

        single_space

        @files_changed_file.each_line do |files_changed_line|
          file_path = "#{@current_directory}/#{files_changed_line.strip}"
          code_file = File.open(file_path, "r") if File.exists?(file_path)
          index = 0
          next unless code_file

          code_file.each_line do |line|
            index += 1
            @forbidden_words.each do |word|
              if line.include?(word)
                found_forbidden = true
                lines_pretty_print Rainbow("-- FORBIDDEN WORD FOUND ON LINE #{index} IN #{files_changed_line.strip}: --").red
                lines_pretty_print Rainbow("   #{line}").yellow
                double_space
              end
            end
          end

          code_file.close
        end

        single_space

        print_header_footer

        single_space
      else
        lines_pretty_print Rainbow('NOT SEARCHING FOR FORBIDDEN WORDS, PER USER INPUT.').red
        single_space
      end

      @files_changed_file.close

      results(found_forbidden)
    end

    def results(found_forbidden)
      if found_forbidden
        single_space
        lines_pretty_print 'Remove offending line(s) and re-run commit statement or run this '\
                           'app again with \'1\' as your second argument to force the commit.'

        single_space
        lines_pretty_print Rainbow('**ONLY FORCE THE COMMIT IF YOU ARE SURE YOU ARE 100% SURE YOU WANT '\
                                   'TO COMMIT THE ABOVE LINES TO YOUR BRANCH!!**').red
        File.delete(@files_changed_file)
        abort
      else
        unless @force_commit
          lines_pretty_print Rainbow('Found 0 forbidden words!').green

          single_space
        end

        File.delete(@files_changed_file)
        commit if @commit_for_user
      end
    end

    def print_header_footer
      puts '***************************************************************************'
    end

    def commit
      if @check_branch
        bash("git rev-parse --abbrev-ref HEAD > #{@current_branch_file_location}")
        current_branch = File.open(@current_branch_file_location, "r").read.strip!

        if @branches_to_check.include?(current_branch)
          lines_pretty_print Rainbow('I\'m sorry, Dave, but I can\'t allow you to do that.').red
          lines_pretty_print Rainbow('You have tried committing to a forbidden branch. Danger, Will Robinson! Danger! '\
                                     'Aborting!').red

          abort
        end
      end

      if @force_commit
        lines_pretty_print 'Skipped checking for forbidden words. Ready to commit now?'
        lines_pretty_print Rainbow('**WARNING: YOU ARE FORCING THE COMMIT WITHOUT CHECKING FOR FORBIDDEN WORDS.**').red

        single_space
      else
        lines_pretty_print 'Okay to commit! Should I go ahead and run the actual commit now?'
      end

      lines_pretty_print 'Please type \'yes\' OR \'y\' to continue. Any other input will be treated as a \'no\'.'

      input = STDIN.gets.chomp.downcase

      single_space

      if input == 'yes' || input == 'y'
        bash(%Q[git commit -m "#{@commit_message}"])
        single_space
        lines_pretty_print 'Committed.'
        single_space
      end
    end

    def set_app_directory
      @app_directory = File.expand_path(File.dirname(__FILE__)).chomp('/lib')
    end

    def restore_woa_settings
      lines_pretty_print 'I see that you have a previous wielder_of_anor installation on this machine.'
      lines_pretty_print Rainbow('Would you like to restore its settings?').yellow

      answered = false

      until answered
        answer = STDIN.gets.strip!

        single_space

        if answer == 'yes' || answer == 'y' || answer == 'no' || answer == 'n'
          answered = true
        else
          lines_pretty_print Rainbow('Please input either \'yes\' or \'no\'.').yellow
        end
      end

      return if answer == 'no' || answer == 'n'

      lines_pretty_print 'One moment, please.'

      single_space

      all_gems = Dir.glob("#{@app_directory.chomp("/wielder_of_anor-#{VERSION}")}/wielder_of_anor*")

      # glob orders things in the array alphabetically, so the second-to-last one in the array is the
      # most recent version that is not the current version.
      previous_config_file = "#{all_gems[-2]}/lib/config.yaml"
      config = YAML.load_file(previous_config_file)
      config['files_changed_file_location'] = "#{@app_directory}/lib/files_changed"
      new_config_file = File.open("#{@app_directory}/lib/config.yaml", 'w')

      YAML.dump(config, new_config_file)
      new_config_file.close

      lines_pretty_print 'Done! Please run me again when you\'re ready.'

      abort
    end

    def bash(command)
      # Dir.chdir ensures all bash commands are being run from the correct
      # directory.
      Dir.chdir(@current_directory) { system "#{command}" }
    end

    def lines_pretty_print(string)
      lines = string.scan(/\S.{0,70}\S(?=\s|$)|\S+/)

      lines.each { |line| puts line }
    end

    def single_space
      puts ''
    end

    def double_space
      puts "\n\n"
    end
  end
end