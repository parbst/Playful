App.ApplicationSerializer = DS.ActiveModelSerializer.extend({});
App.ApplicationAdapter = DS.ActiveModelAdapter.extend({});

App.OrderSerializer = DS.ActiveModelSerializer.extend({
/*
    serializePolymorphicType: function(record, json, relationship) {
        var key = relationship.key,
            belongsTo = get(record, key);
        key = this.keyForAttribute ? this.keyForAttribute(key) : key;
        json[key + "_type"] = belongsTo.constructor.typeKey;
        debugger;
    },
    extractSingle: function(store, type, payload, id, requestType) {
    },
    serializeIntoHash: function(data, type, record, options) {
        var root = Ember.String.decamelize(type.typeKey);
        data[root] = this.serialize(record, options);
    }
*/
    extractArray: function(store, type, payload, id, requestType) {
        App.dataAccess.converter.expandSideLoadedTypes(payload, 'tasks');
        return this._super(store, type, payload, id, requestType);
    }
});
// register rails CSRF token with all requests
$.ready(function(){
    var token = $('meta[name="csrf-token"]').attr('content');
    $.ajaxPrefilter(function( options, originalOptions, jqXHR ) {
        xhr.setRequestHeader('X-CSRF-Token', token)
    });
});

App.dataAccess = {
    converter: {
        toModel: function(modelName){
            return function(rawData){
                var model = eval(modelName);
                if (_.isArray(rawData)){
                    return Em.A(_.map(rawData, function(d){ return model.create(d) }))
                }
                else{
                    return model.create(rawData)
                }
            }
        },
        toEmObject: function(rawData){
            return Em.Object.create(rawData)
        },
        toEmArray: function(rawArray){
            return Em.A(rawArray);
        },
        expandSideLoadedTypes: function(payload, key){
            var types = _.uniq(_.pluck(payload[key], 'type'));
            _.each(types, function(type){
                payload[Em.String.pluralize(type)] = _.filter(payload[key], function(t){ return t.type == type })
            });
        }
    },
    generic: {
        jsonPost: function(url, options){
            options = options || {};
            var convert = options.convert,
                ajaxData = {
                    type: 'POST',
                    url: url,
                    contentType: 'application/json',
                    headers: { Accept : "application/json" },
                    cache: false,
                    dataType: 'json'
                };
            _.each(options.ajax, function(key, value){ ajaxData[key] = value });
            return function(descriptor, onSuccess, onFailure){
                if(_.isFunction(convert)){
                    onSuccess = _.compose(onSuccess, convert)
                }
                ajaxData.data = JSON.stringify(descriptor);
                return $.ajax(ajaxData).done(onSuccess).fail(onFailure);
            }
        },
        jsonGet: function(url, convert){
            return function(descriptor, onSuccess, onFailure){
                if(_.isFunction(convert)){
                    onSuccess = _.compose(onSuccess, convert)
                }
                return $.ajax({
                    type: 'GET',
                    url: url,
                    contentType: 'application/json', 
                    headers: { Accept : "application/json" },
                    cache: false,
                    data: JSON.stringify(descriptor),
                    dataType: 'json'
                }).done(onSuccess).fail(onFailure);
            }
        }
    },
    db: {
        LocalStore: Em.Object.extend({
            data: null,
            storeName: 'unnamed',
            curId: -1,
            init: function(){
                this.set('data', Em.A())
            },
            _recordSet: function(record, prop, val){
                switch(Ember.typeOf(record)){
                    case "instance":
                        record.set(prop, val)
                        break;
                    case "object":
                        record[prop] = val;
                        break;
                }
            },
            _recordGet: function(record, prop){
                var result = null;
                switch(Ember.typeOf(record)){
                    case "instance":
                        result = record.get(prop)
                        break;
                    case "object":
                        result = record[prop]
                        break;
                    default:
                        throw "Store cannot read property of non-object record"
                }
                return result;
            },
            genId: function(){
                return this.get('storeName') + '-' + this.incrementProperty('curId')
            },
            add: function(records){
                var data = this.get('data');
                _.each(records, function(r){ 
                    if(_.isEmpty(this._recordGet(r, 'id'))){
                        this._recordSet(r, 'id', this.genId())
                    }
                    data.push(r) 
                }, this);
            },
            addUniq: function(records){
                var unique = _.reject(records, _.bind(this.contains, this));
                this.add(unique);
            },
            update: function(records, cmpFunc){
                _.each(records, function(r){
                    var oldRecord = this.find(_.partial(cmpFunc, r));
                    this.replace(this._recordGet(oldRecord, 'id'), r);
                }, this);
            },
            find: function(searchFunc){ return _.find(this.get('data'), searchFunc) },
            findAll: function(searchFunc){ return _.filter(this.get('data'), searchFunc) },
            replace: function(id, updatedRecord){
                var oldRecord = this.getByAttr(id);
                if(oldRecord){
                    var data = this.get('data'),
                        idx = _.indexOf(data, oldRecord);
                    this._recordSet(updatedRecord, 'id', this._recordGet(oldRecord, 'id'));
                    data[idx] = updatedRecord;
                }
            },
            contains: function(cmpFunc){
                return this.find(cmpFunc) !== undefined;
            },
            getByAttr: function(value, property){
                if(_.isEmpty(property)){
                    property = 'id'
                }
                var cmp = _.bind(function(r){ return this._recordGet(r, property) == value }, this);
                return this.find(cmp);
            },
            remove: function(value, property){
                var oldRecord = this.getByAttr(id);
                if(oldRecord){
                    var data = this.get('data'),
                        idx = _.indexOf(data, oldRecord);
                    data.splice(idx, 1);
                }
            }
        })
    }
};

App.dataAccess.db.MetadataStore = App.dataAccess.db.LocalStore.extend({
    getSearchString: function(){
        throw "Implement MetadataStore.getSearchString"
    },
    identifierCmp: function(r1, r2){
        return _.isEqual(r1.identifier, r2.identifier);
    },
    findByIdentifier: function(record){
        return this.find(_.partial(this.identifierCmp, record))
    },
    query: function(searchString){
        var regex = new RegExp(_.escapeRegExp(searchString), 'i');
        return this.findAll(_.bind(function(d){
            return regex.test(this.getSearchString(d));
        }, this));
    },
    match: function(searchString){
        var regex = new RegExp("^" + _.escapeRegExp(searchString) + "$", 'i');
        return this.find(_.bind(function(d){
            return regex.test(this.getSearchString(d).trim());
        }, this));
    },
    update: function(records){
        return this._super(records, this.identifierCmp);
    }
});

App.dataAccess.metadata = {
    artist: App.dataAccess.generic.jsonPost(App.config.endpoint.get('metadata.artist'), { convert: App.dataAccess.converter.toEmArray }),
    release: App.dataAccess.generic.jsonPost(App.config.endpoint.get('metadata.release'), { convert: App.dataAccess.converter.toEmArray })
};
App.dataAccess.files = {
    scanByDescriptor: App.dataAccess.generic.jsonPost(App.config.endpoint.get('files.scan'), { convert: App.dataAccess.converter.toModel('App.ScanResult') })
};
App.dataAccess.orders = {
    create: App.dataAccess.generic.jsonPost(App.config.endpoint.get('orders'), { ajax: { dataType: 'text' }})
};
