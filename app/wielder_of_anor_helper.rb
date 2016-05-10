require 'shellwords'
require 'yaml'
require 'rainbow'

class WielderOfAnorHelper
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
    set_app_directory

    first_run unless File.exists?("#{@app_directory}/config/config.yaml")

    config = YAML.load_file("#{@app_directory}/config/config.yaml")
    @commit_message = commit_message
    @force_commit = force_commit
    @current_directory = Dir.pwd
    @files_changed_file_location = config['files_changed_file_location']
    @commit_for_user = config['commit_for_user']

    # Don't want to use a previous version.
    File.delete(@files_changed_file_location) if File.exists?(@files_changed_file_location)

    git_diff

    @files_changed_file = File.open(@files_changed_file_location, "r")
    @forbidden_words = []

    get_forbidden_words(config['forbidden_words_file_location'])
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

  def first_run
    lines_pretty_print 'Thanks for downloading Wielder of Anor! Let\'s run through the '\
         'initial setup!'
    lines_pretty_print Rainbow('**Please ensure your file locations are correct. Wielder of Anor '\
         'does not currently check your input for validity.**').red

    STDIN.gets

    files_changed_file_location = set_files_changed_file_location

    forbidden_words_file_location = set_forbidden_words_file_location

    commit_for_user = set_commit_for_user

    single_space

    set_configs(files_changed_file_location, forbidden_words_file_location, commit_for_user)

    set_forbidden_words(forbidden_words_file_location)
  end

  def set_files_changed_file_location
    set_app_directory

    lines_pretty_print 'Whenever you run Wielder of Anor, it will first run a git diff and '\
         'export the results to a file (so that it\'s only checking the files '\
         'you have actually changed and not your entire code base!). Where '\
         'would you like that file to be located?'
    lines_pretty_print Rainbow('(Just hit enter to accept the default, which is'\
         " #{@app_directory}/docs/files_changed.)").yellow
    files_changed_file_location = STDIN.gets.strip!
    files_changed_file_location = "#{@app_directory}/docs/files_changed" if files_changed_file_location == ''

    files_changed_file_location
  end

  def set_forbidden_words_file_location
    lines_pretty_print 'Your \'forbidden words\' are stored in a file. Where would like that'\
         ' file to be located?'
    lines_pretty_print Rainbow('(Just hit enter to accept the default, which is'\
         " #{@app_directory}/docs/forbidden_words.)").yellow
    forbidden_words_file_location = STDIN.gets.strip!
    forbidden_words_file_location = "#{@app_directory}/docs/forbidden_words" if forbidden_words_file_location == ""

    forbidden_words_file_location
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

    commit_for_user
  end

  def set_configs(files_changed_file_location, forbidden_words_file_location, commit_for_user)
    config = {}
    config['files_changed_file_location'] = files_changed_file_location
    config['forbidden_words_file_location'] = forbidden_words_file_location

    if commit_for_user == 'yes' || commit_for_user == 'y'
      config['commit_for_user'] = true
    elsif commit_for_user == 'no' || commit_for_user == 'n'
      config['commit_for_user'] = false
    end

    file = File.open('config/config.yaml', 'w')
    YAML.dump(config, file)
    file.close
  end

  def set_forbidden_words(forbidden_words_file_location)
    forbidden_words_file = File.open(forbidden_words_file_location, 'w')
    forbidden_words_count = 0

    done = false

    lines_pretty_print 'Great! Now that we\'re done with the files, let\'s add your forbidden '\
                       'words from here!'
    single_space

    until done do
      lines_pretty_print Rainbow('Enter a forbidden word and hit enter. If you are done entering '\
                         'forbidden words, type \'x211\' and hit enter instead.').yellow unless forbidden_words_count > 0

      lines_pretty_print Rainbow('Added! Enter another forbidden word and hit enter. If you are done '\
                                 'entering forbidden words, type \'x211\' and hit enter instead.').yellow unless forbidden_words_count == 0
      word = STDIN.gets.strip!
      single_space

      if word == 'x211'
        done = true
      else
        forbidden_words_file.puts word
        forbidden_words_count += 1
      end
    end

    forbidden_words_file.close

    lines_pretty_print 'And with that, we\'re done! Feel free to run Wielder of Anor again if'\
         ' you\'d like to check your code now!'

    abort
  end

  def bash(command)
    # Dir.chdir ensures all bash commands are being run from the correct
    # directory.
    Dir.chdir(@current_directory) { system "#{command}" }
  end

  def git_diff
    bash("git diff HEAD --name-only --staged > #{@files_changed_file_location}")
  end

  def get_forbidden_words(file_location)
    forbidden_words_file = File.open(file_location)

    forbidden_words_file.each_line do |line|
      @forbidden_words << line.strip
    end

    forbidden_words_file.close
  end

  def wielder_of_anor
    found_forbidden = false

    # If we're forcing the commit, don't bother checking for forbidden words.
    unless @force_commit
      count = File.foreach(@files_changed_file).inject(0) {|c, line| c+1}

      if count == 0
        lines_pretty_print 'No files have been added. Please use the git add command to add files to your '\
                           'commit.'

        abort
      end

      print_header_footer

      @files_changed_file.each_line do |files_changed_line|
        code_file = File.open("#{@current_directory}/#{files_changed_line.strip}", "r")
        index = 0

        code_file.each_line do |line|
          index += 1
          @forbidden_words.each do |word|
            if line.include?(word)
              found_forbidden = true
              lines_pretty_print "-- FORBIDDEN WORD FOUND ON LINE #{index} IN #{files_changed_line.strip}: --"
              lines_pretty_print "   #{line.strip!}"
              double_space
            end
          end
        end

        code_file.close
      end

      print_header_footer
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
        lines_pretty_print 'FOUND 0 FORBIDDEN WORDS.'
      end

      File.delete(@files_changed_file)
      commit if @commit_for_user
    end
  end

  def print_header_footer
    puts '***************************************************************************'
  end

  def commit
    if @force_commit
      lines_pretty_print 'Skipped checking for forbidden words. Ready to commit now?'
      lines_pretty_print Rainbow('**WARNING: YOU ARE FORCING THE COMMIT WITHOUT CHECKING FOR FORBIDDEN WORDS.**').red
    else
      lines_pretty_print 'Okay to commit! Should I go ahead and run the actual commit now?'
    end

    lines_pretty_print 'Please type \'yes\' OR \'y\' to continue. Any other input will be treated as a \'no\'.'

    single_space

    input = STDIN.gets.chomp.downcase

    if input == 'yes' || input == 'y'
      bash(%Q[git commit -m "#{@commit_message}"])
      single_space
      lines_pretty_print 'Committed.'
    end
  end

  def set_app_directory
    @app_directory = File.expand_path(File.dirname(__FILE__)).chomp('/app')
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
