require 'rubygems'
require 'linnaeus'
require 'net/http'
require 'json'

class OiBuddy

  attr_accessor :trainer, :classify

  CONTEXT_MAPS = {
    :stay_room_service =>  [%w(room bedsheet linen fridge tv television towel toilet toiletry bathroom shower order tooth paste toothpaste manager luggage bell-boy roomservice room-service minibar), %w(need want bring clean services get service)],
    :stay_emergency => [%w(police emergency fire ambulance thief doctor), %w(steal)],
    :stay_laundry => [%w( laundry clothes detergent shirt jeans dry clean), %w(clean wash dirty stinky)],
    :stay_beverage => [%w(coffee tea  water beverage  milk juice), %w(order bring drinks)],
    :stay_taxi => [%w(cab taxi ola uber auto tfs airport car), %w(ride drop order reach book)],
    :stay_breakfast => [%w(breakfast cornflakes menu bread butter food morning complimentary), %w(eat)],
    :stay_lunch_dinner => [%w(lunch menu dinner buffeet food hungry cafe), %w(eat)],
    :stay_nearby_food => [%w(restaurant zomato online food lunch dinner pizza continental chinese indian hungry cafes desserts), %w(dining nearby outside delivery eat )],
    :stay_nearby_travel => [%w(places tourism metro rail bus airport train temples park mall amusement park aquarium gallery saloon movie bank library museum zoo), %w(nearby visit travel tourist historic)],
    # :stay_extend => [%w( booking extra), %w(extend stay lengthen)],
    :stay_money => [%w(amount money wallet points credits), %w(pay checkout)],
    :stay_weather => [%w(weather rain sunny sunset humit mausam temperature), %w(forecast rainy)],
    :stay_wifi => [%w(internet wifi wi-fi wireless network password login credentials creds username net), %w(connect details )],
    :stay_directions => [%w(location oyo latitude longitude hotel maps), %w(route direction navigate nearest reach find )],
    :stay_doctor => [%w(doctor practo dentist surgeon hospital health appointment headache pain clinic labs fever sick diagnose), %w(book care checkup)],
    :booking_details => [%w(booking stay checkin invoice), %w(book)]
  }

  def initialize()
    self.trainer  = ::Linnaeus::Trainer.new(scope: "seqtest")    # Used to train documents
    self.classify = ::Linnaeus::Classifier.new(scope: "seqtest")   # Used to classify documents
  end

  def feed_data
    CONTEXT_MAPS.each do |context,kwords|
      all_resp = []
      kwords[0].each{ |s| all_resp.concat(weighted_synonyms(s,false)) }
      kwords[1].each{ |s| all_resp.concat(weighted_synonyms(s,true)) }

      puts "Training #{context} => #{all_resp.join(' ,')}"
      all_resp.each do |s|
        self.trainer.train context,s.to_s
      end
    end
  end

  def get_context input
    res, matches, total_count = self.classify.classify(input)
    if matches >= 2 || (matches.to_f/total_count) > 0.2
      return {status: 'true', result: res}
    else
      return {status: 'false', response: 'Not enough data. Please try something else'}
    end
  end


  private

  def weighted_synonyms keyword, is_verb
    syns = []
    syns.concat([keyword]*8)

    resp = Net::HTTP.get(URI.parse(URI.encode("http://words.bighugelabs.com/api/2/28dfc9fa2e62f6710d013d7a68a57ecc/"+keyword+"/json")))
    begin
      resp = JSON.parse resp
    rescue=> e
      return syns
    end

    #handle noun
    max = is_verb ? 2:5
    syns.concat(get_words_with_weights(resp.delete('noun'),max))

    #handle verb
    max = is_verb ? 4:2
    syns.concat(get_words_with_weights(resp.delete('verb'),max))

    resp.each do |k,v|
      syns.concat(get_words_with_weights(v,3))
    end

    puts "synonms for #{keyword} => #{syns}"
    syns.flatten.uniq
  rescue => e
    syns
  end

  def get_words_with_weights response,max_value
    return if response.nil?
    arr = []
    words = (response).values.flatten.uniq.first(max_value)
    words.each_with_index{|a,i| arr.concat([a]*(max_value-i))}
    return arr
  end

end

