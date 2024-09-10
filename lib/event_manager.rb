require 'marshal'

class Hangman
  MAX_GUESSES = 6
  SAVE_FILE = 'hangman_save.dat'

  def initialize
    @guessed_letters = []
    @remaining_guesses = MAX_GUESSES
    @word_progress = []
    @random_word = ''
  end

  def play
    load_game if File.exist?(SAVE_FILE) && yes_or_no?("A saved game was found. Do you want to resume it? (y/n): ")
    
    random_word if @random_word.empty?
    
    until game_over?
      display_game_state
      action = choose_action
      case action
      when 'guess'
        user_letter
      when 'save'
        save_game
        puts "Game saved. You can resume later."
        return
      when 'quit'
        puts "Thanks for playing!"
        return
      end
      update_game_state
    end
    display_result
    File.delete(SAVE_FILE) if File.exist?(SAVE_FILE)
  end

  def random_word
    words = File.readlines('google-10000-english-no-swears.txt').map(&:strip)
    @valid_words = words.select { |word| (5..12).include?(word.length) }
    @random_word = @valid_words.sample
    @word_progress = Array.new(@random_word.length, '_')
    puts "The word is #{@random_word.length} letters long"
    @random_word
  end

  def user_letter
    puts "Guess a letter"
    letter = gets.chomp.downcase
    if @guessed_letters.include?(letter)
      puts "You've already guessed that letter. Try again."
    else
      @guessed_letters << letter
      if @random_word.include?(letter)
        puts "Correct! '#{letter}' is in the word."
        update_word_progress(letter)
      else
        @remaining_guesses -= 1
        puts "Wrong! '#{letter}' is not in the word. You have #{@remaining_guesses} guesses left."
      end
    end
  end

  def update_word_progress(letter)
    @random_word.chars.each_with_index do |char, index|
      @word_progress[index] = letter if char == letter
    end
  end

  def display_game_state
    puts "\nWord: #{@word_progress.join(' ')}"
    puts "Guessed letters: #{@guessed_letters.join(', ')}"
    puts "Remaining guesses: #{@remaining_guesses}"
  end

  def update_game_state
    # This method is called after each guess, but doesn't need to do anything
    # since we update the game state in other methods
  end

  def game_over?
    @word_progress.join == @random_word || @remaining_guesses == 0
  end

  def display_result
    if @word_progress.join == @random_word
      puts "Congratulations! You've guessed the word: #{@random_word}"
    else
      puts "Game over! The word was: #{@random_word}"
    end
  end

  def save_game
    game_state = {
      guessed_letters: @guessed_letters,
      remaining_guesses: @remaining_guesses,
      word_progress: @word_progress,
      random_word: @random_word
    }
    File.open(SAVE_FILE, 'wb') { |file| Marshal.dump(game_state, file) }
  end

  def load_game
    game_state = Marshal.load(File.read(SAVE_FILE))
    @guessed_letters = game_state[:guessed_letters]
    @remaining_guesses = game_state[:remaining_guesses]
    @word_progress = game_state[:word_progress]
    @random_word = game_state[:random_word]
    puts "Game loaded successfully!"
  end

  def choose_action
    loop do
      puts "Choose an action: (g)uess a letter, (s)ave game, or (q)uit"
      choice = gets.chomp.downcase
      return 'guess' if choice == 'g' || choice == 'guess'
      return 'save' if choice == 's' || choice == 'save'
      return 'quit' if choice == 'q' || choice == 'quit'
      puts "Invalid choice. Please try again."
    end
  end

  def yes_or_no?(prompt)
    loop do
      print prompt
      choice = gets.chomp.downcase
      return true if choice == 'y' || choice == 'yes'
      return false if choice == 'n' || choice == 'no'
      puts "Invalid input. Please enter 'y' or 'n'."
    end
  end
end

# Create and start a new game
game = Hangman.new
game.play