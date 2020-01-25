class CreateMovies < ActiveRecord::Migration[6.0]
  def change
    create_table :movies do |t|
      t.string :index
      t.string :title
      t.string :theater
      t.string :latitude
      t.string :longitude
      t.string :description, limit: 500
      t.string :link
      t.string :time
      t.string :all_time
      t.string :review
      t.string :release_date
      t.string :drop_path
      t.string :poster_id
      
      t.timestamps
    end
  end
end
