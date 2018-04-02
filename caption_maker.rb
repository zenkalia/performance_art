require 'pry'
require_relative 'lib/syllablecount'

SYLLABLES_PER_SEC = 3.0

class Time
  def to_subrip
    self.strftime('%H:%M:%S,%L')
  end
end

def prompt(*args)
  print(*args)
  gets
end

puts 'Welcome to subtitle generator.'
puts 'Press Enter to begin. Ctrl+D on an empty line to finish.'

lol = prompt '---'
exit unless lol == "\n"

lines = []

class Line
  attr_accessor :body, :time
  def initialize(body)
    @body = body.chomp
    @time = Time.now
  end

  def length
    @length ||= @body.syllable_count / SYLLABLES_PER_SEC
  end
end

typing_start_time = Time.now

while (lol = prompt '> ') != nil
  lines.push Line.new lol
end

typing_end_time = Time.now

puts '---'
puts 'Great, now where should the subtitles start and end?'

start_time = end_time = nil
time_parser = /(\d+):(\d+)/

while start_time == nil
  start_time_string = prompt 'Start Time? (mm:ss) '
  end_time_string = prompt 'End Time? (mm:ss) '

  start_parsed = time_parser.match(start_time_string)
  end_parsed = time_parser.match(end_time_string)

  next unless start_parsed && end_parsed

  start_time = Time.new(2018, 1, 1, 0, start_parsed[1], start_parsed[2])
  end_time = Time.new(2018, 1, 1, 0, end_parsed[1], end_parsed[2])
end

total_syllable_count = lines.map { |line| line.body.syllable_count }.sum
total_syllable_time = total_syllable_count / SYLLABLES_PER_SEC

total_time = end_time - start_time
total_typing_time = typing_end_time - typing_start_time
space_time = total_time - total_syllable_time

time_multiplier = space_time / total_typing_time

current_time = start_time.dup

file = File.open('output.srt', 'w')


lines.each_with_index do |line, index|
  current_time += (line.time - lines[index-1].time) * time_multiplier if index > 0

  file.write "#{index+1}\n"
  file.write "#{current_time.to_subrip} --> #{(current_time + line.length).to_subrip}\n"
  file.write "#{line.body}\n"
  file.write "\n"

  current_time += line.length
end

file.close
