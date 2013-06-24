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
Class for Race ?
=end

class Car
  # Class level


  # Instance level
  attr_accessor :number, :driver, :total_distance, :speed

  def initialize(number, driver)
    @number = number.to_i
    @driver = driver.to_s
    @total_distance = 0 # The race will be 500 miles long
    @speed = rand(80..100) # Every minute cars travel between 80-100 miles
  end

  def race
    @total_distance += @speed
    @speed = rand(80..100)
  end

end

class Race
  # Class level


  # Instance level
  attr_accessor :gp, :prize, :cars, :race_order, :miles, :date

  def initialize(name, prize, miles, *cars)
    @gp = name.to_s
    @prize = prize.to_i
    @cars = []
    @race_order = {}
    @miles = miles
    @date = Time.now
    cars.each do |car|
      @cars << car
      @race_order[car] = car.total_distance
    end
  end

  def print_date
    puts @date.strftime('%a %d %b %Y')
  end

  def print_results
    system "clear"
    puts "----------------------------"
    print_date
    puts "#{@gp} race to #{@miles} mi."
    puts "----------------------------"
    position = 0
    @race_order.each_pair do |car, distance|
      puts "Position #{position += 1}: Car #{car.number} driven by #{car.driver} traveled #{distance} mi."
    end
  end

  def take_a_spin
    @cars.each do |car|
      car.race
      @race_order[car] = car.total_distance
    end
    print_results
  end

  def order_racers
    
  end

end

system "clear"