# frozen_string_literal: false

require 'English'

# An addon to the String class to change the colour of the text
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def integer?
    /\A[-+]?\d+\z/.match?(self)
  end
end

def choose_game_option(game)
  puts "Please select an option by entering an appropriate number:\n"\
  "1 - Start a new game\n2 - Load an existing game\n"

  game.start(gets.chomp)
end

# A letter object that also stores the guess state of the letter
class LetterObject
  attr_reader :letter, :color_code

  def initialize(letter)
    @letter = letter
    @status = 'No_Guess'
    @color_code = find_color_code
  end

  def status=(value)
    @status = value
    @color_code = find_color_code
  end

  def display_letter
    print @letter.colorize(@color_code)
  end

  private

  def find_color_code
    color_codes = { 'No_Guess' => 39, 'Right_Guess' => 32, 'Wrong_Guess' => 31 }
    color_codes[@status.to_s]
  end
end

# The game module responsible for handling the guesses made by the player
module GuessHandler
  def guess_letter(letter_choice)
    if letter_choice.match?(/[[:alpha:]]/)
      register_letter_guess(letter_choice)
    else
      puts 'That wasn\'t a valid letter choice. Try again!'
    end
  end

  def guess_word(word)
    if word.match?(/[[:alpha:]]/)
      register_word_guess(word)
    else
      puts 'That\'s not even a word. Try again!'
    end
  end

  private

  def register_letter_guess(letter_choice)
    guess_is = @secret_array.any?(letter_choice) ? 'Right_Guess' : 'Wrong_Guess'

    update_available_letters(guess_is, letter_choice)

    update_correct_letters(letter_choice)

    if guess_is == 'Right_Guess'
      @solved = @correct_letters.none?('_')
    else
      @no_of_wrong_guesses += 1
      @man_hung = @no_of_wrong_guesses == @max_wrong_guess
    end
  end

  def register_word_guess(word)
    if word == @secret_word
      @solved = true
    else
      @no_of_wrong_guesses += 1
      @man_hung = @no_of_wrong_guesses == @max_wrong_guess
    end
  end
end

# The game module responsible for generating the secret word
module SecretWordMaker
  def select_word(words)
    word_acceptable = false

    until word_acceptable
      rand(1..61_406).times { words.gets }
      secret_word = $LAST_READ_LINE.to_s.chomp.downcase
      words.rewind
      word_acceptable = secret_word.strip.length > 5 && secret_word.strip.length < 12 ? true : false
    end
    p secret_word
    secret_word
  end

  def define_secret_word
    words = File.open('5desk.txt')

    @secret_word = select_word(words)

    @secret_array = @secret_word.split('')

    @secret_word.length.times { @correct_letters.push('_') }
  end
end

# The game board module to handle display of the current game status
module GameBoard
  def draw_gameboard(secret_word, no_of_wrong_guesses, hangman)
    board_width = 32

    draw_board_top(board_width, secret_word)
    puts " \n"
    draw_man(no_of_wrong_guesses, hangman)
    repeat_print(board_width, '=')
    guesses_left(board_width)
    puts " \n\n"
  end

  def display_letter_options
    puts "Letter choices:\n"\
    "  #{"\u2022".encode('UTF-8')} White letters are still available\n"\
    "  #{"\u2022".encode('UTF-8')} #{'Green'.colorize(32)} letters - correct guess\n"\
    "  #{"\u2022".encode('UTF-8')} #{'Red'.colorize(31)} letters - incorrect guess\n"\
    " \n"

    @available_letters.each do |letter_object|
      letter_object.display_letter
      print ', ' unless letter_object.letter == 'z'
    end
  end

  private

  def draw_board_top(board_width, secret_word)
    secret_word_length = secret_word.length
    sw_filler_space = (((32 - (secret_word_length * 2)) / 2) - 1)

    repeat_print(board_width, '=')
    puts ''
    print '|'
    repeat_print(sw_filler_space, ' ')
    print @correct_letters.join(' ')
    repeat_print(sw_filler_space + 1, ' ')
    print "|\n"
    repeat_print(board_width, '=')
  end

  def draw_man(no_of_wrong_guesses, hangman)
    hangman.update_man(no_of_wrong_guesses)

    hangman.man_array.each { |line_array| puts line_array.join('') }
  end

  def repeat_print(number_of, str)
    number_of.times { print str }
  end

  def guesses_left(board_width)
    statement = "| Guesses left: #{@max_wrong_guess - @no_of_wrong_guesses}"
    print " \n"
    print statement
    repeat_print(board_width - statement.length - 1, ' ')
    print "|\n"
    repeat_print(board_width, '=')
  end
end

# The man class for display the hang man
class Man
  attr_accessor :man_array

  def initialize
    @line1_array = blank_line_array
    @line2_array = blank_line_array
    @line3_array = blank_line_array
    @line4_array = blank_line_array
    @line5_array = blank_line_array
    @line6_array = blank_line_array
    @line7_array = blank_line_array
    @man_array = [@line1_array, @line2_array, @line3_array, @line4_array,
                  @line5_array, @line6_array, @line7_array]
  end

  def update_man(no_of_wrong_guesses)
    case no_of_wrong_guesses
    when 1..2
      update_man_first(no_of_wrong_guesses)
    when 3..5
      update_man_second(no_of_wrong_guesses)
    when 6..9
      update_man_third(no_of_wrong_guesses)
    when 10
      @line6_array[20..21] = '\, '.split(',').flatten
    end
  end

  private

  def update_man_first(no_of_wrong_guesses)
    case no_of_wrong_guesses
    when 1
      @line3_array[14] = '|'
      @line4_array[14] = '|'
      @line5_array[14] = '|'
      @line6_array[14] = '|'
    when 2
      @line2_array[14..19] = Array.new(6, '_').flatten
    end
  end

  def update_man_second(no_of_wrong_guesses)
    case no_of_wrong_guesses
    when 3
      @line3_array[16] = '/'
      @line4_array[15] = '/'
    when 4
      @line3_array[19] = '|'
    when 5
      @line4_array[19] = 'O'
    end
  end

  def update_man_third(no_of_wrong_guesses)
    case no_of_wrong_guesses
    when 6
      @line5_array[19] = '|'
    when 7
      @line5_array[17..18] = "',-".split(',').flatten
    when 8
      @line5_array[20..21] = "-,'".split(',').flatten
    when 9
      @line6_array[18] = '/'
    end
  end

  def blank_line_array
    Array.new(30, ' ').unshift('|').push('|')
  end
end

# The hangman game class
class Game
  include GameBoard
  include SecretWordMaker
  include GuessHandler

  attr_reader :secret_word

  def initialize
    @secret_word = ''
    @guess_number = 0
    @max_wrong_guess = 10
    @no_of_wrong_guesses = 0
    @secret_array = []
    @available_letters = []
    @correct_letters = []
    @man_hung = false
    @solved = false
    @hangman = Man.new
  end

  def start(choice)
    case choice
    when '1'
      new_game
    when '2'
      load_game
    else
      puts "Sorry, I didn\'t quite catch that..."
      choose_game_option(self)
    end
  end

  private

  def new_game
    define_secret_word
    @available_letters = [*('a'..'z')].map { |letter| LetterObject.new(letter) }

    puts "The secret word has been defined. You have 9 attempts to correctly guess the word.\n"\
    "Good Luck!\n\n"

    play_round until @man_hung || @solved

    draw_gameboard(@secret_word, @no_of_wrong_guesses, @hangman)

    end_game
  end

  def load_game
    puts 'I will load a game at some point!'
  end

  def play_round
    draw_gameboard(@secret_word, @no_of_wrong_guesses, @hangman)

    display_letter_options

    puts " \n\n"\
    'Please enter a letter, guess the word or enter nothing to automatically save the game:'
    execute_gameplay(gets.chomp.downcase)
  end

  def execute_gameplay(letter_choice)
    case letter_choice.length
    when 0
      save_game
    when 1
      guess_letter(letter_choice)
    else
      guess_word(letter_choice)
    end
  end

  def save_game
    puts 'I will save the game at some point!'
  end

  def update_available_letters(guess_is, letter_choice)
    @available_letters = @available_letters.map do |letter_object|
      letter_object.status = guess_is if letter_choice == letter_object.letter
      letter_object
    end
  end

  def update_correct_letters(letter_choice)
    @correct_letters = @correct_letters.map.with_index do |letter, index|
      letter_choice == @secret_array[index] ? letter_choice : letter
    end
  end

  def end_game
    if @man_hung
      puts "Sorry, you\'ve been hung!! The secret word was \'#{@secret_word}\'"
    elsif @solved
      puts 'Congratulations, you found the word!!'
    end
  end
end

game = Game.new

puts "          *** Welcome to Hangman ***          \n"\
" \n"
choose_game_option(game)
# |                              |
# |            ______            |
# |            | /  |            |
# |            |/   O            |
# |            |  '-|-'          |
# |            |   / \           |
# |                              |
