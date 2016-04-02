require 'active_support/concern'

module EasySetters
  extend ActiveSupport::Concern

=begin
  {
    actor_name:           String,
    actor_image_url:      String,
    character_name:       String,
    character_image_url:  String,
    order:                Integer
  }
=end
  def add_casts(casts_def)
    casts = Array(casts_def).map do |c|
      actor = Actor.ensure(name: c[:actor_name], image_url: c[:actor_image_url])
      Cast.ensure(actor: actor, character_name: c[:character_name], order: c[:order], model: self, character_image_url: c[:image_url])
    end
    self.casts += casts.select {|c| !self.casts.include?(c) }
  end

=begin
  {
    character_name:       String
  }
=end
  def remove_casts(casts_def)
    character_names = casts_def.pluck(:character_name)
    self.casts = self.casts.select { |c| !character_names.include?(c.character) }
  end

=begin
  {
    character_name:       String,
    character_image_url:  String,
    order:                Integer
  }
=end
  def change_casts(casts_def)
    character_names = casts_def.pluck(:character_name)
    self.casts.select {|c| character_names.include?(c.character) }.each do |cast|
      cast_def = casts_def.find {|cd| cd.character_name == cast.character }
      cast.order = cast_def[:order] if cast_def.has_key?(:order)
      cast.character_image_url = cast_def[:character_image_url] if cast_def.has_key?(:character_image_url)
    end
  end

  def update_casts(all_casts_def)
    all_casts_def ||= {}
    add_casts(all_casts_def[:add]) if all_casts_def.has_key?(:add)
    change_casts(all_casts_def[:change]) if all_casts_def.has_key?(:change)
    remove_casts(all_casts_def[:delete]) if all_casts_def.has_key?(:delete)
  end

  def add_genres(genres_def)
    genres = Array(genres_def).map {|g| Genre.ensure(g) }
    self.genres += genres.select {|g| !self.genres.include?(g) }
  end

  def remove_genres(genres_def)
    genres = Array(genres_def).map {|g| Genre.ensure(g) }
    self.genres = self.genres.select {|g| !genres.include?(g)}
  end

  def update_genres(all_genres_def)
    all_genres_def ||= {}
    add_genres(all_genres_def[:add]) if all_genres_def.has_key?(:add)
    remove_genres(all_genres_def[:delete]) if all_genres_def.has_key?(:delete)
  end

  def add_languages(languages_def)
    languages = Array(languages_def).map {|l| Language.ensure(l) }
    self.languages += languages.select {|l| !self.languages.include?(l) }
  end

  def remove_languages(languages_def)
    languages = Array(languages_def).map {|l| Language.ensure(l) }
    self.languages = self.languages.select {|l| !languages.include?(l)}
  end

  def update_languages(all_languages_def)
    all_languages_def ||= {}
    add_languages(all_languages_def[:add]) if all_languages_def.has_key?(:add)
    remove_languages(all_languages_def[:delete]) if all_languages_def.has_key?(:delete)
  end
=begin
  def set_languages(languages_def, overwrite_with_nil = false)
    if languages_def.is_a?(Array)
      self.languages = languages_def.map { |l| Language.ensure(l) }
    elsif languages_def.nil? && overwrite_with_nil
      self.languages = []
    end
  end
=end
  private

  def get_obj_value(object, field)
    if object.is_a?(Hash)
      object[field]
    else
      object.respond_to?(field) ? object.send(field) : nil
    end
  end
end
