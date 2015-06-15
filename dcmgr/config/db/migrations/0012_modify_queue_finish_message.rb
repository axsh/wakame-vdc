# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:queued_jobs) do
      set_column_type(:failure_reason, 'text')
      rename_column(:failure_reason, :finish_message)
    end
  end

  down do
    alter_table(:queued_jobs) do
      rename_column :finish_message, :failure_reason
      set_column_type :failure_reason, "varchar(255)", :null=>true
    end
  end
end

