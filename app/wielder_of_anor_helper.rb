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
  
  def initialize(commit_message, force_commit, current_directory)
    config = YAML.load_file('config/config.yaml')
    
    @app_directory = config['app_directory']
    @commit_message = commit_message
    @force_commit = force_commit
    @current_directory = current_directory
    @files_changed_file_location = config['files_changed_file_location']
    @commit_for_user = config['commit_for_user']
    
    git_diff
    
    @files_changed_file = File.open(@files_changed_file_location, "r")
    @forbidden_words = []
    
    get_forbidden_words(config['forbidden_words_file_location'])
  end
  
  def bash(command)
    # Dir.chdir ensures all bash commands are being run from the correct
    # directory.
    Dir.chdir(@app_directory) { system "#{command}" }
  end
  
  # Some commands need to be run through Shellwords.escape to actually run
  # on bash.
  def bash_escaped(command)
    escaped_command = Shellwords.escape(command)
    Dir.chdir(@app_directory) { system "#{escaped_command}" }
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
        puts
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

    if input == "yes" || input == "y"
      bash("git commit -a -m #{@commit_message}")
      puts "COMMITED."
    end
  end
end