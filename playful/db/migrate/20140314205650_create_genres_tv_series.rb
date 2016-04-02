class CreateGenresTvSeries < ActiveRecord::Migration
  def change
    create_table :genres_tv_series, id: false do |t|
      t.integer :genre_id
      t.integer :tv_series_id
    end
  end
end