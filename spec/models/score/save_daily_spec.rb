require 'spec_helper'

describe Score, 'save daily' do
  before(:each) do
    @now = Time.now
    Time.stub!(:now).and_return(@now)
  end

  it "saves a new daily score if the player doesn't have a score for today" do
    @player = Factory.build(:player)
    @leaderboard = Factory.build(:leaderboard)
    
    @player.stub!(:high_scores).and_return(Factory.build(:high_scores, {:leaderboard => @leaderboard}))
    Score.save(@leaderboard, @player, 100)
    
    Score.daily_collection.count.should == 1
    score_should_exist(100)
  end
  it "saves the new daily score id to the high scores" do
    @player = Factory.build(:player)
    @leaderboard = Factory.build(:leaderboard)
    scores = Factory.build(:high_scores, {:leaderboard => @leaderboard})
    
    @player.stub!(:high_scores).and_return(scores)
    Score.save(@leaderboard, @player, 100)
      
    Score.daily_collection.find({:_id => scores.daily.id}).count.should == 1
  end
  it "saves a new daily score if the player's current daily is lower than the new one" do
    @player = Factory.build(:player)
    @leaderboard = Factory.build(:leaderboard)
    create_high_score(99)
    
    Score.save(@leaderboard, @player, 100)
    Score.daily_collection.count.should == 1
    score_should_exist(100)
  end
  it "does not save the score if the user's current daily is higher than the new one" do
    @player = Factory.build(:player)
    @leaderboard = Factory.build(:leaderboard)
    create_high_score(150)
    
    Score.save(@leaderboard, @player, 149)
    Score.daily_collection.count.should == 1
    score_should_exist(150)
  end
  
  
  def score_should_exist(points)
    selector = {:lid => @leaderboard.id, :un => @player.username, :p => points, :ss => @leaderboard.daily_stamp, :dt => @now}
    Score.daily_collection.find(selector).count.should == 1
  end
  def create_high_score(points)
    score_id = Score.daily_collection.insert({:lid => @leaderboard.id,
      :ss => @leaderboard.daily_stamp, :p => points, :un => @player.username, :dt => @now})

    Factory.create(:high_scores, {:leaderboard_id => @leaderboard.id, :unique => @player.unique, :userkey => @player.unique, 
      :daily => Factory.build(:high_score, {:points => points, :stamp => @leaderboard.daily_stamp, :id => score_id})})
  end
end