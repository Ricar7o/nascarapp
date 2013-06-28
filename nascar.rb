# =========================================================

require 'Twitter'
require 'gmail'
require 'active_support/core_ext/integer/inflections'

Twitter.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
end

class Car
  # Class level
  @@all_cars = []
  @@max_speed = 0.0

  def self.get_max_speed
    @@max_speed
  end

  def self.set_max_speed
    @@max_speed = 0.0
    @@all_cars.each do |car|
      @@max_speed = car.speed if @@max_speed < car.speed
    end
  end

  def self.get_all_cars
    @@all_cars
  end

  def self.set_speed
    now = Time.now
    @@all_cars.each do |car|
      score = 0
      Twitter.search("##{car.driver}", :count => 100).results.each do |tweet|
        gap = now - tweet.created_at
        if gap < 30
          score += 97
        elsif gap < 300
          score += 31
        elsif gap < 3600
          score += 6
        elsif gap < 3600*6
          score += 2
        else
          score += 1
        end
      end
      car.speed = score
    end
  end

  def self.normalize_speed(miles)
    @@all_cars.each do |car|
      car.speed = car.speed / @@max_speed.to_f * miles / 3
      car.final_lap = (miles - car.total_distance) / car.speed
    end
  end

  # Instance level
  attr_accessor :number, :driver, :total_distance, :speed, :final_lap

  def initialize(number, driver)
    @number = number.to_i
    @driver = driver.to_s.capitalize
    @total_distance = 0.0 # The race will be 500 miles long
    @speed = 1.0 #rand(80.0..100.0) # Every minute cars travel between 80-100 miles
    @final_lap = 2.0
    @@all_cars << self
  end

  def race
    @total_distance += @speed
  end

  def draw_car(blankspace, info = '')
    blankspace.to_i.times do print " " end
    puts "  __~@\\___"
    blankspace.to_i.times do print " " end
    puts "~'≠0---0--`##{@driver} No. #{@number} #{info}"
    blankspace.to_i.times do print " " end
    puts "-  -  -  -  -  -  -  -  -  -  -  -  -"
  end

end

class Race
  # Class level

  # Instance level
  attr_accessor :gp, :prize, :cars, :race_order, :miles, :date, :final_results

  def initialize(name, prize, miles, cars)
    @gp = name.to_s
    @prize = prize.to_i
    @cars = cars
    @race_order = []
    @miles = miles
    @date = Time.now
    @final_results = []
  end

  def print_date
    puts @date.strftime('%a %d %b %Y')
  end

  def print_header(label)
    system "clear"
    puts "----------------------------"
    print_date
    puts "#{@gp} race to #{@miles} mi."
    puts label.to_s.upcase
    puts "----------------------------"
  end

  def print_distances
    print_header("Current distances traveled")
    position = 0
    spacer = @cars.count
    @cars.each do |car|
      # puts "#{position += 1}: Car #{car.number} driven by #{car.driver} traveled #{car.total_distance.round(2)} mi."
      car.draw_car((spacer-=1)*10, "| #{(car.total_distance*100).floor / 100.0} mi.")
    end
  end

  def send_email #HTML version
    position = 0
    puts "Sending email..."
    email_subj = "Twitter GP: #{@gp.to_s} has ended."
    email_body = "<h2>Here are the results for the <strong style='color:#00FFFF;'>Twitter GP of #{gp.to_s}</strong>:</h2>"
    email_body << "<br /><hr><br />"
    @final_results.each do |car,time|
      email_body << "<p><span style='font-size:30px;'>#{(position += 1).ordinalize}</span> Car No. #{car.number} driven by <span style='color:#0000FF'>##{car.driver}</span></p>"
    end
    gmail = Gmail.connect(ENV['GMAIL_NAME'], ENV['GMAIL_PASS'])
    gmail.deliver do
      to ENV['GMAIL_ACT']
      subject email_subj
      html_part do
        content_type 'text/html; charset=UTF-8'
        body email_body
      end
    end
    # email.deliver!
    # gmail.logout
    print_final_results
    puts "Email sent."
  end

  def take_a_spin # Right now it's adding the cars again to the @race_order
    temp = [] # Array to sort the cars that are finishing in the same interval, sort them, then push them sorted to the final_results array
    Car.set_speed
    Car.set_max_speed
    Car.normalize_speed(@miles)
    @cars.each do |car|
      car.race
      if (0.0...1.0).include?(car.final_lap) # If the final_lap value is between 0.0 and 1.0, that means they're finishing the race in the next take_a_spin
        temp << [car,car.final_lap]
      end
    end
    temp.sort_by! {|car,time| time}
    temp.each do |car_with_time|
      final_results << car_with_time
    end
    order_racers
    if finished?
      award_ceremony
    else
      print_distances
    end
  end

  def finished?
    if @final_results.count == @cars.count
      print_final_results
      return true
    else
      return false
    end
  end

  def award_ceremony
    puts "Every car has pitted."
    send_email
    return "Check your email for a copy of the results."
  end

  def order_racers
    @cars.sort_by! {|car| car.total_distance}.reverse!
  end

  def print_final_results
    print_header("Final race results")
    position = 0
    spacer = @final_results.count
    @final_results.each do |car,time|
      puts "#{(position += 1).ordinalize}: Car No. #{car.number} driven by #{car.driver}"
      car.draw_car((spacer-=1)*10)
    end
  end

end


# Script starts here
system "clear"

puts "Twitter Grand Prix"
puts "--- Car Registration ---"
puts "Write 'done' to finish the registration"
number = 0
while true do
  puts "Choose a hashtag (without the '#') to fuel car ##{number+=1}:"
  hashtag = gets.chomp.to_s.downcase
  if hashtag == "done"
    break
  else
    Car.new(number, hashtag)
  end
end

puts "--- Race creation ---"
puts "What is the name of the race?"
name = gets.chomp.to_s.capitalize
puts "How long is the race (in miles)?"
mi = gets.chomp.to_i
race = Race.new(name, 1000, mi, Car.get_all_cars)
while !race.finished?
  race.take_a_spin
  puts "Press Enter to continue..."
  gets
  puts "Cars are racing..."
end
