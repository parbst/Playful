import Ember from 'ember';

export default Ember.Mixin.create({
    getJson: function() {
        return Ember.copy(this.get('_attributes'));
/*
        var v, ret = [];
        for (var key in this) {
            if (this.hasOwnProperty(key)) {
                v = this[key];
                if (v === 'toString') {
                    continue;
                } // ignore useless items
                if (Ember.typeOf(v) === 'function') {
                    continue;
                }
                ret.push(key);
            }
        }
        return this.getProperties.apply(this, ret);
*/
    }
});
