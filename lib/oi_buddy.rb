require 'rubygems'
require 'linnaeus'
require 'net/http'
require 'json'

class OiBuddy

  attr_accessor :trainer, :classify

  CONTEXT_MAPS = {
    :stay_room_service => %w(room service get bedsheet linen fridge tv television towel toilet bathroom tooth paste toothpaste manager luggage bell-boy ),
    :stay_emergency => %w(police ambulance thief stole doctor),
    :stay_laundry => %w(clean laundry wash clothes detergent shirt jeans),
    :stay_beverage => %w(coffee tea order bring water beverage drinks milk juice),
    :stay_taxi => %w(order cab taxi ola uber tfs reach book car),
    :stay_breakfast => %w(eat breakfast lunch cornflakes menu bread butter food morning complimentary),
    :stay_lunch_dinner => %w(lunch menu dinner price),
    :stay_nearby_food => %w(restaurant nearby zomato food outside order eat pizza continental chinese indian),
    :stay_nearby_travel => %w(nearby places visit travel tourism tourist historic temples park mall ),
    :stay_extend => %w(extend booking extra stay lengthen),
    :stay_money => %w(amount money pay wallet checkout price),
    :stay_weather => %w(weather rain sunny sunset forecast),
    :stay_wifi => %w(connect internet wifi wi-fi wireless network password username),
    :stay_directions => %w(route direction navigate location oyo nearest latitude longitude maps )
  }

  def initialize()
    self.trainer  = ::Linnaeus::Trainer.new(scope: "test3")    # Used to train documents
    self.classify = ::Linnaeus::Classifier.new(scope: "test3")   # Used to classify documents
  end

  def feed_data
    CONTEXT_MAPS.each do |context,kwords|
      all_resp = []
      kwords.each do |s|
        all_resp.concat(synonym_for(s))
      end
      puts "Training #{context} => #{all_resp.join(' ,')}"
      all_resp.each do |s|
        self.trainer.train context,s.to_s
      end
    end
  end

  def get_context input
    res, matches, total_count = self.classify.classify(input)
    if matches >= 2 || (matches.to_f/total_count) > 50
      return {status: 'true', result: res}
    else
      return {status: 'false', response: 'Not enough data. Please try something else'}
    end
  end


  private

  def synonym_for keyword
    syns = []
    resp = Net::HTTP.get(URI.parse(URI.encode("http://words.bighugelabs.com/api/2/6383e9d8b64f77d040ce1a8a483a1406/"+keyword+"/json")))
    resp = JSON.parse resp rescue nil
    resp.each do |s|
      ordered_words = s[1].values.flatten.uniq.first(4) rescue []
      ordered_words.each_with_index{|a,i| syns.concat([a]*(4-i))}
    end
    syns.concat([keyword]*6)
    puts "synonms for #{keyword} => #{syns}"
    syns.flatten.uniq
  rescue => e
    syns
  end

end

