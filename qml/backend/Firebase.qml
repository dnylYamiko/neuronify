pragma Singleton

import QtQuick 2.7
import Qt.labs.settings 1.0
import Neuronify 1.0

DownloadManager {
    id: root
    property bool debug: true
    property string userId
    property string refreshToken
    property string idToken
    property string objectId
    property var settings: Settings {
        id: settings
        category: "firebase"
        property alias refreshToken: root.refreshToken
    }

    property var config: {
        return {
            apiKey: "AIzaSyAaTf5yA2Hz9mSJjIPJYwDLjXbr-B2ecMY",
            authDomain: "neuronify.firebaseapp.com",
            databaseURL: "https://neuronify.firebaseio.com",
            projectId: "neuronify",
            storageBucket: "neuronify.appspot.com",
            messagingSenderId: "483464139976"
        };
    }

    readonly property bool loggedIn: {
        return refreshToken !== "" && idToken !== ""
    }

    onRefreshTokenChanged: {
        if (debug) {
            console.log("Refresh token changed to", refreshToken)
        }
        if(!refreshToken) {
            objectId = ""
            return
        }
        var url = "https://securetoken.googleapis.com/v1/token?key=" + config.apiKey
        var req = new XMLHttpRequest()
        req.open("POST", url)
        req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        req.onreadystatechange = function() {
            processReply(req, function(result) {
                idToken = result.id_token
                userId = result.user_id
                console.log("Successfully logged in with previous token.")
            })
        }
        req.send('grant_type=refresh_token&refresh_token=' + refreshToken);
    }

    function processReply(req, callback) {
        if (req.readyState === XMLHttpRequest.DONE) {
            if(debug) {
                console.log("Response:", req.responseText)
            }
            if(callback) {
                var result = JSON.parse(req.responseText)
                if(result.errors !== undefined) {
                    console.error("Error parsing", req.responseText)
                    return
                }
                callback(result)
                return result
            }
        }
    }

    function serialize(obj) {
        var str = [];
        for(var p in obj) {
            str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
        }
        return str.join("&");
    }

    function login(username, password, callback) {
        var url = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=" + config.apiKey
        var req = new XMLHttpRequest()
        req.open("POST", url)
        req.setRequestHeader("Content-Type", "application/json")
        req.onreadystatechange = function() {
            processReply(req, function(result) {
                if(result.refreshToken) {
                    refreshToken = result.refreshToken
                }
                if(callback) {
                    callback(result)
                }
            })
        }
        if (debug) {
            console.log("GET", url)
        }
        req.send(JSON.stringify({"email": username, "password": password, "returnSecureToken":true}));
    }

    function buildUrl(name) {
        var url = config.databaseURL + "/" + name
        if (idToken) {
            url += "?auth=" + idToken
        }
        console.log("Built URL", url)
        return url
    }

    function buildUploadUrl(name) {
        return "https://firebasestorage.googleapis.com/v0/b/" + config.storageBucket + "/o?name=" + name
    }

    function get(name, callback) {
        var req = new XMLHttpRequest;
        var url = buildUrl(name)
        req.open("GET", url);
        req.onreadystatechange = function() {
            processReply(req, callback)
        }
        if (debug) {
            console.log("GET", url)
        }
        req.send();
    }

    function downloadData(url, callback) {
        var req = new XMLHttpRequest
        req.open("GET", url)
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                if(debug) {
                    console.log("Downloaded", url)
                }
                if(callback) {
                    callback(req.responseText)
                }
            }
        }
        if (debug) {
            console.log("GET", url)
        }
        req.send()
    }

    function put(name, data, callback) {
        var req = new XMLHttpRequest;
        var url = buildUrl(name)
        req.open("PUT", url);
        req.onreadystatechange = function() {
            processReply(req, callback)
        }
        if (debug) {
            console.log("PUT", url)
        }
        req.send(JSON.stringify(data));
    }

    function post(name, data, callback) {
        var req = new XMLHttpRequest;
        var url = buildUrl(name)
        req.open("POST", url);
        req.onreadystatechange = function() {
            processReply(req, callback)
        }
        if (debug) {
            console.log("POST", url, data)
            console.log("Data", JSON.stringify(data))
        }
        req.send(JSON.stringify(data));
    }

    function upload(name, data, callback) {
        var url = buildUploadUrl(name)
        var req = new XMLHttpRequest()
        req.open("POST", url)
        req.setRequestHeader("Content-Type", "text/plain");
        req.setRequestHeader("Authorization", "Firebase " + idToken)
        req.onreadystatechange = function() {
            console.log("RESPONSE DATA", req.responseText)
            processReply(req, function(result){
                console.log("Upload successfull!")
                callback(result)
            })
        }
        if (debug) {
            console.log("POST", url, data)
            console.log("Data", JSON.stringify(data))
        }
        req.send(JSON.stringify(data, null, 4));

//        var req = new XMLHttpRequest;
//        var url = serverUrl + "files/" + name
//        req.open("POST", url);
//        setHeaders(req)
//        req.setRequestHeader("Content-Type", "text/plain");
//        req.onreadystatechange = function() {
//            if(req.readyState == XMLHttpRequest.DONE) {
//                var result = JSON.parse(req.responseText)
//                callback(result)
//            }
//        }
//        if (debug) {
//            console.debug("POST", url)
//        }
//        req.send(JSON.stringify(data, null, 4));
    }

    function logout() {
        refreshToken = ""
        if(loggedIn) {
            console.error("ERROR: Could not log out user:", refreshToken, objectId)
        }
    }

    function createModel(response) {
        var model = []
        for (var i in response) {
            var item = response[i]
            if (item === true) {
                item = {}
            }

            if (typeof(item) !== typeof({})) {
                console.error("Response is not an object. Cannot create model!")
                return
            }

            item._key = i
            model.push(item)
        }
        console.log("Created model from", JSON.stringify(response), "to", JSON.stringify(model))
        return model
    }
}
