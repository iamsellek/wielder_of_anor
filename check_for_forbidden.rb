require 'shellwords'

def bash(command)
  escaped_command = Shellwords.escape(command)
  system "git commit -a -m #{escaped_command}"
end

commit_message = ARGV[0]
force_commit = ARGV[1]
found_forbidden = false

forbidden_words = ["binding", "pry", "test_output", "console.log", "Rails.logger.debug", "puts"]
file_with_changed_files_list = "/Users/csellek/workspace/reverbnation/files_changed"

file = File.open(file_with_changed_files_list, "r")

puts "*****************************************************************"
puts "\n\n"

file.each_line do |file_line|
  file_line.strip!
  code_file = File.open("/Users/csellek/workspace/reverbnation/#{file_line}", "r")
  index = 0
  
  code_file.each_line do |line|
    index += 1
    forbidden_words.each do |word|
      if line.include?(word)
        found_forbidden = true
        puts "-- FORBIDDEN WORD FOUND ON LINE #{index} IN #{file_line}: --"
        puts "   #{line.strip!}"
        puts "\n\n"
      end
    end
  end
end

if found_forbidden
  puts "*****************************************************************"
  puts "\n\n"
  puts "REMOVE OFFENDING LINE(S) AND RE-RUN COMMIT STATEMENT OR RUN THIS "\
       "APP AGAIN WITH '1' AS YOUR SECOND ARGUMENT TO FORCE THE "\
       "COMMIT."
  puts "**ONLY FORCE THE COMMIT IF YOU ARE SURE YOU ARE 100% SURE YOU WANT "\
       "TO COMMIT THE ABOVE LINES TO YOUR BRANCH!!**"
  File.delete(file_with_changed_files_list)
  abort
else
  puts "FOUND 0 FORBIDDEN WORDS."
  puts "\n\n"
end

puts "*****************************************************************"
puts "\n\n"

File.delete(file_with_changed_files_list)

puts "OKAY TO COMMIT. SHOULD I RUN THE ACTUAL COMMIT NOW?"

input = STDIN.gets.chomp

if input == "yes" || input == "y"
  bash("#{commit_message}")
  puts "COMMITED."
end