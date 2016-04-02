import Ember from 'ember';
import { DataTableColumn } from 'playful/components/data-table';
import _ from 'lodash';

export default Ember.Component.extend({
  model: null,
  classNames: ['release-metadata'],
  _tableColumns: Ember.A([
    DataTableColumn.create({ property: 'trackNumber' }),
    DataTableColumn.create({ property: 'title' })
  ]),
  _tableEntries: function(){
    return this.get('model.tracks') || Ember.A();
  }.property('model', 'model.tracks', 'model.tracks.length'),
  actions: {
    changeCover: function(){
      this.sendAction('changeCover', this.get('model'));
    }
  },
  artist: function(){
    return _.uniq(_.invoke(this.get('model.artists')), 'get', 'artistName').join(', ');
  }.property('model.artists.[]'),
  totalDiscs: function(){
    return _.uniq(_.invoke(this.get('model.tracks'), 'get', 'discNumber')).length;
  }.property('model.tracks.[]')
});


