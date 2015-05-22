Sequel.migration do
  up do
    alter_table(:load_balancers) do
      add_column :allow_list, "text", :null=>true
    end
  end

  down do
    alter_table(:load_balancers) do
      drop_column :allow_list
    end
  end
end
