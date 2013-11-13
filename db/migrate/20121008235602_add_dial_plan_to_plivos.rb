class AddDialPlanToPlivos < ActiveRecord::Migration
  def change
    #Plan de marcado para este plivo
    add_column :plivos, :dial_plan, :text
    add_column :plivos, :dial_plan_desc, :text
  end
end
