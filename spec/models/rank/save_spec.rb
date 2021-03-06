require 'spec_helper'

describe Rank, :save do
  it "saves a daily rank" do
    leaderboard = FactoryGirl.build(:leaderboard)
    key = "lb:d:#{leaderboard.id}:#{leaderboard.daily_stamp.strftime("%y%m%d%H")}"

    Rank.save(leaderboard, LeaderboardScope::Daily, "leto-one", 200)

    Store.redis.zcard(key).should == 1
    rank = Store.redis.zrange(key, 0, 1, {:with_scores => true})
    rank[0].should == ["leto-one", 200.0]
  end

  it "saves a weekly rank" do
    leaderboard = FactoryGirl.build(:leaderboard, {:offset => -4})
    key = "lb:w:#{leaderboard.id}:#{leaderboard.weekly_stamp.strftime("%y%m%d%H")}"

    Rank.save(leaderboard, LeaderboardScope::Weekly, "paul-d", 328)

    Store.redis.zcard(key).should == 1
    rank = Store.redis.zrange(key, 0, 1, {:with_scores => true})
    rank[0].should == ["paul-d", 328.0]
  end

  it "saves an overall rank" do
    leaderboard = FactoryGirl.build(:leaderboard, {:offset => 6})
    key = "lb:o:#{leaderboard.id}"

    Rank.save(leaderboard, LeaderboardScope::Overall, "jessica-b", 948)

    Store.redis.zcard(key).should == 1
    rank = Store.redis.zrange(key, 0, 1, {:with_scores => true})
    rank[0].should == ["jessica-b", 948.0]
  end

  it "overwrites a player's existing rank" do
    leaderboard = FactoryGirl.build(:leaderboard, {:offset => 6})
    key = "lb:o:#{leaderboard.id}"

    Rank.save(leaderboard, LeaderboardScope::Overall, "jessica-b", 222)
    Rank.save(leaderboard, LeaderboardScope::Overall, "jessica-b", 948)

    Store.redis.zcard(key).should == 1
    rank = Store.redis.zrange(key, 0, 1, {:with_scores => true})
    rank[0].should == ["jessica-b", 948.0]
  end
end