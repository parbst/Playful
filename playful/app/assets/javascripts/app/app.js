window.App = Em.Application.create({
	title: 'Playful',
    config: {
        endpoint: {
            get: function(endpointName){
                var host = 'http://localhost:3000'
                    map = {
                        'host':         host,
                        'metadata':         "/metadata",
                        'files.scan':       "/files/scan",
                        'files.download':   "/files/download",
                        'files':            "/files",
                        'shares':           "/shares",
                        'orders':           "/orders"
                    };
                    map['metadata.artist'] = map.metadata + "/artist";
                    map['metadata.release'] = map.metadata + "/release";

                return (endpointName != 'host' ? host : '') + map[endpointName];
            }
        }
    },
    log: {
        error: function(message){
            window.Playful = window.Playful || {};
            window.Playful.errorArguments = arguments;
            console.error("Playful error: " + message, arguments);
        },
        info: function(message){
            console.info("Playful info: " + message, arguments);
        }
    }
});
