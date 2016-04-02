class CreateLanguagesTvSeries < ActiveRecord::Migration
  def change
    create_table :languages_tv_series, id: false do |t|
      t.integer :language_id
      t.integer :tv_series_id
    end
  end
end