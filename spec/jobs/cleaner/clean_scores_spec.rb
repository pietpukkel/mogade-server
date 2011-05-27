require 'spec_helper'
require './deploy/jobs/cleaner'

describe Cleaner, 'clean scores' do

  it "clears our daily high score pointers older than 3 days" do
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 1, :stamp => Time.now.utc - 43400})})
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 2, :stamp => Time.now.utc - 1 * 86400})})
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 3, :stamp => Time.now.utc - 2 * 86400})})
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 4, :stamp => Time.now.utc - 3 * 86400})})
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 5, :stamp => Time.now.utc - 4 * 86400})})
    Factory.create(:high_scores, {:daily => Factory.build(:high_score, {:id => 6, :stamp => Time.now.utc - 5 * 86400})})
    
    Cleaner.new.clean_scores
    HighScores.count.should == 6
    assert_scrubbed(:daily, [4, 5, 6])
  end

  it "clears out daily scores older than 3 days" do
    Score.daily_collection.insert({:ss => Time.now.utc - 43400})
    Score.daily_collection.insert({:ss => Time.now.utc - 1 * 86400})
    Score.daily_collection.insert({:ss => Time.now.utc - 2 * 86400})
    Score.daily_collection.insert({:ss => Time.now.utc - 3 * 86400})
    Score.daily_collection.insert({:ss => Time.now.utc - 4 * 86400})
  
    Cleaner.new.clean_scores
    Score.daily_collection.count.should == 3
    Score.daily_collection.find({:ss => {'$gt' => Time.now.utc - 3 * 86400}}).count.should == 3
  end
  
  it "clears our weekly high score pointers older than 10 days" do
    Factory.create(:high_scores, {:weekly => Factory.build(:high_score, {:id => 1, :stamp => Time.now.utc - 43400})})
    Factory.create(:high_scores, {:weekly => Factory.build(:high_score, {:id => 2, :stamp => Time.now.utc - 4 * 86400})})
    Factory.create(:high_scores, {:weekly => Factory.build(:high_score, {:id => 3, :stamp => Time.now.utc - 9 * 86400})})
    Factory.create(:high_scores, {:weekly => Factory.build(:high_score, {:id => 4, :stamp => Time.now.utc - 11 * 86400})})
    Factory.create(:high_scores, {:weekly => Factory.build(:high_score, {:id => 5, :stamp => Time.now.utc - 12 * 86400})})
    
    Cleaner.new.clean_scores
    HighScores.count.should == 5
    assert_scrubbed(:weekly, [4, 5])
  end
  
  it "clears out weekly scores older than 10 days" do
    Score.weekly_collection.insert({:ss => Time.now.utc - 43400})
    Score.weekly_collection.insert({:ss => Time.now.utc - 1 * 86400})
    Score.weekly_collection.insert({:ss => Time.now.utc - 8 * 86400})
    Score.weekly_collection.insert({:ss => Time.now.utc - 9 * 86400})
    Score.weekly_collection.insert({:ss => Time.now.utc - 10 * 86400})
    Score.weekly_collection.insert({:ss => Time.now.utc - 12 * 86400})
    
    Cleaner.new.clean_scores
    Score.weekly_collection.count.should == 4
    Score.weekly_collection.find({:ss => {'$gt' => Time.now.utc - 10 * 86400}}).count.should == 4
  end
  
  private
  def assert_scrubbed(scope, ids)
    HighScores.find.each do |score|
      ids.include?(score.send("#{scope}").id).should be_false
    end
  end
end