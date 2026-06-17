class CreateDateParsers < ActiveRecord::Migration[7.1]
  def change
    create_table :date_parsers do |t|
      t.timestamps
    end
  end
end
