Sequel.migration do
  up do
    alter_table(:load_balancers) do
      add_column :httpchk_path, "text", :null=>true
    end
  end

  down do
    drop_table(:load_balancers) do
      drop_column :httpchk_path
    end
  end
end
