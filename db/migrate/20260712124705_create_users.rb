class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :timezone, null: false
      t.time :preferred_email_time, null: false
      t.datetime :next_email_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :next_email_at
  end
end
