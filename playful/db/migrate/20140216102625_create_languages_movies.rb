class CreateLanguagesMovies < ActiveRecord::Migration
  def change
    create_table :languages_movies, id: false do |t|
      t.integer :language_id
      t.integer :movie_id
    end
  end
end
