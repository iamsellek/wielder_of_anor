require 'shellwords'
require 'yaml'

class WielderOfAnorHelper
  ##############################################################################
  ##############################################################################
  ## commit_message is the git commit message the user would like to send     ##
  ## once we have verified that there are no forbidden words present in their ##
  ## code.                                                                    ##
  ##                                                                          ##
  ## force_commit is either '1' or nil. If it's 1, we will commit later even  ##
  ## if there are forbidden words present.                                    ##
  ##                                                                          ##
  ## current_directory is the directory that the user is in when they run     ##
  ## Wielder of Anor, so (it should be) the code directory they'd like to     ##
  ## check for forbidden words.                                               ##
  ##############################################################################
  ##############################################################################

  def initialize(commit_message, force_commit)
    @app_directory = File.expand_path(File.dirname(__FILE__)).chomp('/app')

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

  def self.help
    puts "Wielder of Anor can accept up to two parameters on run. The first"\
         " parameter can be:"
    puts "- Your eventual commit message (in quotes). Ignored if you have not"\
         " allowed Wielder of Anor to commit for you."
    puts "- help - You should already know what this does :)."
    puts "- config - Re-runs the initial set up."

    abort
  end

  def first_run
    puts "Thanks for downloading Wielder of Anor! Let's run through the"\
         " initial setup!"
    puts "**Please ensure your file locations are correct. Wielder of Anor"\
         " does not currently check your input for validity.**"

    files_changed_file_location = set_files_changed_file_location(@app_directory)

    puts "\n\n"

    forbidden_words_file_location = set_forbidden_words_file_location(@app_directory)

    puts "\n\n"

    commit_for_user = set_commit_for_user

    set_configs(@app_directory, files_changed_file_location, forbidden_words_file_location, commit_for_user)

    puts "\n\n"

    set_forbidden_words(forbidden_words_file_location)
  end

  def set_app_directory(running_directory)
    puts "Please copy and paste the location of the parent Wielder of Anor"\
         " directory."
    puts "(Just hit enter to accept the directory it's currently located,"\
         " which is #{running_directory}.)"
    app_directory = STDIN.gets.strip!
    app_directory = running_directory if app_directory == ""

    app_directory
  end

  def set_files_changed_file_location(running_directory)
    puts "Whenever you run Wielder of Anor, it will first run a git diff and"\
         " export the results to a file (so that it's only checking the files"\
         " you have actually changed and not your entire code base!). Where"\
         " would you like that file to be located?"
    puts "(Just hit enter to accept the default, which is"\
         " #{running_directory}/docs/files_changed.)"
    files_changed_file_location = STDIN.gets.strip!
    files_changed_file_location = "#{running_directory}/docs/files_changed" if files_changed_file_location == ""

    files_changed_file_location
  end

  def set_forbidden_words_file_location(running_directory)
    puts "Your 'forbidden words' are stored in a file. Where would like that"\
         " file to be located?"
    puts "(Just hit enter to accept the default, which is"\
         " #{running_directory}/docs/forbidden_words.)"
    forbidden_words_file_location = STDIN.gets.strip!
    forbidden_words_file_location = "#{running_directory}/docs/forbidden_words" if forbidden_words_file_location == ""

    forbidden_words_file_location
  end

  def set_commit_for_user
    puts "Would you like Wielder of Anor to run your commits for you once you"\
         " have verified that your code is free of forbidden words?"
    puts "('yes' or 'no'. Just hitting enter defaults to no.)"
    commit_for_user = STDIN.gets.strip!.downcase
    commit_for_user = "no" if commit_for_user == ""

    commit_for_user
  end

  def set_configs(app_directory, files_changed_file_location, forbidden_words_file_location, commit_for_user)
    config = {}

    config["app_directory"] = app_directory
    config["files_changed_file_location"] = files_changed_file_location
    config["forbidden_words_file_location"] = forbidden_words_file_location

    if commit_for_user == "yes" || commit_for_user == "y"
      config["commit_for_user"] = true
    elsif commit_for_user == "no" || commit_for_user == "n"
      config["commit_for_user"] = false
    end

    file = File.open("config/config.yaml", "w")
    YAML.dump(config, file)
    file.close
  end

  def set_forbidden_words(forbidden_words_file_location)
    forbidden_words_file = File.open(forbidden_words_file_location, "w")

    done = false
    puts "Great! Now that we're done with the files, let's add your forbidden"\
         " words from here!"

    while !done do
      puts "Enter a forbidden word and hit enter. If you are done entering"\
           " forbidden words, type 'x211' and hit enter instead."
      word = STDIN.gets.strip!

      puts "\n\n"

      if word == "x211"
        done = true
      else
        forbidden_words_file.puts word
      end
    end

    forbidden_words_file.close

    puts "And with that, we're done! Feel free to run Wielder of Anor again if"\
         " you'd like to check your code now!"

    abort
  end

  def bash(command)
    # Dir.chdir ensures all bash commands are being run from the correct
    # directory.
    Dir.chdir(@current_directory) { system "#{command}" }
  end

  # Some commands need to be run through Shellwords.escape to actually run
  # on bash.
  # TODO Deprecate this - looks like it's unnecessary.
  def bash_escaped(command)
    escaped_command = Shellwords.escape(command)
    Dir.chdir(@current_directory) { system "#{escaped_command}" }
  end

  def git_diff
    bash("git diff HEAD  --name-only > #{@files_changed_file_location}")
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

    print_header_footer

    # Don't bother checking if we're forcing the commit, since we're going to
    # commit either way.
    unless @force_commit
      @files_changed_file.each_line do |files_changed_line|
        code_file = File.open("#{@current_directory}/#{files_changed_line.strip}", "r")
        index = 0

        code_file.each_line do |line|
          index += 1
          @forbidden_words.each do |word|
            if line.include?(word)
              found_forbidden = true
              puts "-- FORBIDDEN WORD FOUND ON LINE #{index} IN #{files_changed_line.strip}: --"
              puts "   #{line.strip!}"
              puts "\n\n"
            end
          end
        end
        
        code_file.close
      end
    else
      puts "NOT SEARCHING FOR FORBIDDEN WORDS, PER USER INPUT."
      puts "\n\n"
    end

    print_header_footer

    @files_changed_file.close

    results(found_forbidden)
  end

  def results(found_forbidden)
    if found_forbidden
      puts "REMOVE OFFENDING LINE(S) AND RE-RUN COMMIT STATEMENT OR RUN THIS "\
           "APP AGAIN WITH '1' AS YOUR SECOND ARGUMENT TO FORCE THE "\
           "COMMIT."
      puts "**ONLY FORCE THE COMMIT IF YOU ARE SURE YOU ARE 100% SURE YOU WANT "\
           "TO COMMIT THE ABOVE LINES TO YOUR BRANCH!!**"
      File.delete(@files_changed_file)
      abort
    else
      unless @force_commit
        puts "FOUND 0 FORBIDDEN WORDS."
        puts "\n\n"
      end

      File.delete(@files_changed_file)
      commit if @commit_for_user
    end
  end

  def print_header_footer
    puts "*****************************************************************"
    puts "\n\n"
  end

  def commit
    if @force_commit
      puts "SKIPPED CHECKING FOR FORBIDDEN WORDS. READY TO COMMIT NOW?"
      puts "**YOU ARE FORCING THE COMMIT WITHOUT CHECKING FOR FORBIDDEN WORDS.**"
    else
      puts "OKAY TO COMMIT. SHOULD I RUN THE ACTUAL COMMIT NOW?"
    end

    puts "PLEASE TYPE 'YES' OR 'Y' TO CONTINUE."

    input = STDIN.gets.chomp.downcase

    puts "\n\n"

    if input == "yes" || input == "y"
      bash(%Q[git commit -a -m "#{@commit_message}"])
      puts "\n\n"
      puts "COMMITED."
      puts "\n\n"
    end
  end
end
