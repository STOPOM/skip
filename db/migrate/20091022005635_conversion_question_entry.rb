class ConversionQuestionEntry < ActiveRecord::Migration
  def self.up
    BoardEntry.category_like('質問').each do |entry|
      entry.aim_type = 'question'
      entry.hide = entry.last_updated <= Time.now.ago(10.day)
      entry.save
    end
  end

  def self.down
    raise IrreversibleMigration
  end

  class ::BoardEntry < ActiveRecord::Base
  end
end
