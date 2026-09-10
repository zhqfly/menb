class CreateIextResourceTables < ActiveRecord::Migration[7.0]
  def change
    create_table :iext_holidays do |t|
      t.date :occurred_on, null: false
      t.string :name, null: false
      t.string :kind, null: false, default: 'holiday'
      t.integer :user_id
      t.decimal :hours, precision: 8, scale: 2, default: 0
      t.timestamps null: false
    end
    add_index :iext_holidays, :occurred_on
    add_index :iext_holidays, :user_id

    create_table :iext_shift_rules do |t|
      t.integer :user_id, null: false
      t.integer :weekday, null: false
      t.decimal :capacity_hours, precision: 8, scale: 2, null: false, default: 8
      t.string :shift_name
      t.boolean :active, default: true, null: false
      t.timestamps null: false
    end
    add_index :iext_shift_rules, %i[user_id weekday]

    create_table :iext_resource_alerts do |t|
      t.integer :user_id, null: false
      t.date :spent_on, null: false
      t.string :kind, null: false
      t.decimal :hours, precision: 8, scale: 2
      t.text :message
      t.datetime :resolved_at
      t.timestamps null: false
    end
    add_index :iext_resource_alerts, %i[user_id spent_on kind]
  end
end
