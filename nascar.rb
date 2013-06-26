=begin
NascarApp - Car racing mini-game
1. There are several car objects with randomly generated distances traveled every period of time.
2. Everytime the last car passes through the starting line, we paint a picture that shows where each
car is in relation to the others.
3. We take in bets on each car using the Twitter API from a specific account.
4. If that account is @mentioned and the tweet follows a format, we place the bet for that person.
5. Every elapsed lap, the bets are worth less and less.
6. At the end of the race, we publish the results.
7. We print out a summary of earnings and payments.
=end

=begin
Needs:
Class for Car
Class for Bet
Class for Race
=end

# ============================================================================
ENV

require 'Twitter'

# TWITTER_CONSUMER_KEY
# TWITTER_CONSUMER_SECRET
# TWITTER_OAUTH_TOKEN
# TWITTER_OAUTH_TOKEN_SECRET

Twitter.configure do |config|
  config.consumer_key = "KiJd5QifsgI3OhK22JgA"
  config.consumer_secret = "BgiPakQWqJSig97g2rbNMT0DKNpWQTK1SlIgpQPRGSU"
  config.oauth_token = "207616489-y7egtxiWiVCrY65aFpr9x0XXpNk3DUpwr2juEw2k"
  config.oauth_token_secret = "PTmTtDDcnImT9Jr6TLiMBhvplxPSN9rkzJIiHpjE"
end

class Car
  # Class level
  @@max_speed = 0.0
  # Instance level
  attr_accessor :number, :driver, :total_distance, :speed, :final_lap

  def initialize(number, driver)
    @number = number.to_i
    @driver = driver.to_s
    @total_distance = 0.0 # The race will be 500 miles long
    @speed = 0.0 #rand(80.0..100.0) # Every minute cars travel between 80-100 miles
    @final_lap = 2.0
  end

  def race
    @total_distance += @speed
    @speed = set_speed
  end

  def draw_car(blankspace, info = '')
    blankspace.to_i.times do print " " end
    puts "  __~@\\___"
    blankspace.to_i.times do print " " end
    puts "~'≠0---0--`#{@driver} ##{@number} #{info}"
    blankspace.to_i.times do print " " end
    puts "-  -  -  -  -  -  -  -  -  -  -  -  -"
  end

  def set_speed
    total = 0
    now = Time.now
    Twitter.search("##{@driver}", :count => 100).results.each do |tweet|
      gap = now - tweet.created_at
      if gap < 60
        total += 97
      elsif gap < 3600
        total += 17
      elsif gap < 3600*6
        total += 6
      elsif gap < 3600*24
        total += 2
      else
        total += 1
      end
    end
    return total
  end

end

class Race
  # Class level

  # Instance level
  attr_accessor :gp, :prize, :cars, :race_order, :miles, :date, :final_results

  def initialize(name, prize, miles, *cars)
    @gp = name.to_s
    @prize = prize.to_i
    @cars = []
    @race_order = []
    @miles = miles
    @date = Time.now
    @final_results = []
    cars.each do |car|
      @cars << car
    end
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
      car.draw_car((spacer-=1)*10, "| #{car.total_distance.round(2)} mi.")
    end
  end

  def take_a_spin # Right now it's adding the cars again to the @race_order
    return "Every car has pitted." if finished?
    temp = [] # Array to sort the cars that are finishing in the same interval, sort them, then push them sorted to the final_results array
    @cars.each do |car|
      car.race
      if (0.0..1.0).include?(car.final_lap) # If the final_lap value is between 0.0 and 1.0, that means they're finishing the race in the next take_a_spin
        temp << [car,car.final_lap]
      end
      car.final_lap = (@miles - car.total_distance) / car.speed # Calculate the next final_lap time for each car
    end
    temp.sort_by! {|car,time| time}
    temp.each do |car_with_time|
      final_results << car_with_time
    end
    order_racers
    if finished?
      return "Every car has pitted." 
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

  def order_racers
    @cars.sort_by! {|car| car.total_distance}.reverse!
  end

  def print_final_results
    print_header("Final race results")
    position = 0
    spacer = @final_results.count
    @final_results.each do |car,time|
      puts "#{position += 1}: Car #{car.number} driven by #{car.driver}"
      car.draw_car((spacer-=1)*10)
    end
  end

  # def photo_finish(car)
  #   temp = [] # Array to sort the cars that are finishing in the same interval, sort them, then push them sorted to the final_results array
  #   if (0.0..1.0).include?(car.final_lap) # If the final_lap value is between 0.0 and 1.0, that means they're finishing the race in the next take_a_spin
  #     temp << [car,car.final_lap]
  #   end
  #   temp.sort_by! {|car,time| time}
  #   temp.each do |car_with_time|
  #     final_results << car_with_time
  #   end
  #   car.final_lap = (@miles - car.total_distance) / car.speed
  # end

end

system "clear"