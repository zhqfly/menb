class CreateIextCostEvmTables < ActiveRecord::Migration[7.0]
  def change
    create_table :iext_cost_items do |t|
      t.integer :project_id, null: false
      t.integer :work_package_id
      t.integer :user_id
      t.string :category, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.date :occurred_on, null: false
      t.string :vendor
      t.string :subject, null: false
      t.text :notes
      t.timestamps null: false
    end
    add_index :iext_cost_items, :project_id
    add_index :iext_cost_items, :occurred_on
    add_index :iext_cost_items, :category

    create_table :iext_budget_baselines do |t|
      t.integer :project_id, null: false
      t.integer :user_id
      t.string :version, null: false
      t.jsonb :snapshot, default: {}
      t.text :notes
      t.timestamps null: false
    end
    add_index :iext_budget_baselines, %i[project_id version], unique: true

    create_table :iext_evm_snapshots do |t|
      t.integer :project_id, null: false
      t.integer :user_id
      t.date :as_of, null: false
      t.decimal :bac, precision: 15, scale: 2
      t.decimal :pv, precision: 15, scale: 2
      t.decimal :ac, precision: 15, scale: 2
      t.decimal :ev, precision: 15, scale: 2
      t.decimal :spi, precision: 10, scale: 4
      t.decimal :cpi, precision: 10, scale: 4
      t.decimal :eac, precision: 15, scale: 2
      t.decimal :cv, precision: 15, scale: 2
      t.decimal :sv, precision: 15, scale: 2
      t.jsonb :breakdown, default: {}
      t.timestamps null: false
    end
    add_index :iext_evm_snapshots, %i[project_id as_of]
  end
end
