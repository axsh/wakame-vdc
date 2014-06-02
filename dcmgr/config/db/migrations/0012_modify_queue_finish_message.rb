# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:queued_jobs) do
      set_column_type(:failure_reason, 'text')
      rename_column(:failure_reason, :finish_message)
    end
  end

  down do
  end
end

