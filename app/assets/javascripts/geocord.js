
/**
 * 
 */
function get_current_location()
{
    if (navigator.geolocation)
    {
        navigator.geolocation.getCurrentPosition(
            _on_success,
            function (e) { alert(e.message); },
            { "enableHighAccuracy": true, "timeout": 20000, "maximumAge": 2000 }
        );
    }
}

/**
 * 
 * @param {*} position 
 */
function _on_success(position)
{
    $('body').append("<div id='current_latitude' class='none'>" + position.coords.latitude + "</div>");
    $('body').append("<div id='current_longitude' class='none'>" + position.coords.longitude + "</div>");
}

/**
 * 
 * @param {*} lat1 
 * @param {*} lng1 
 * @param {*} lat2 
 * @param {*} lng2 
 */
function get_distance(lat1, lng1, lat2, lng2)
{
    var location_array = new Array(lat1, lng1, lat2, lng2);
    lat1 *= Math.PI / 180;
    lng1 *= Math.PI / 180;
    lat2 *= Math.PI / 180;
    lng2 *= Math.PI / 180;

    if (location_array.indexOf(0) >= 0 ||
        location_array.indexOf(undefined) >= 0 ||
        location_array.indexOf(null) >= 0)
    {
        return 0.0;
    }
    var distance = 6371 * Math.acos(Math.cos(lat1) * Math.cos(lat2) * Math.cos(lng2 - lng1) + Math.sin(lat1) * Math.sin(lat2));
    return distance.toFixed(1);
}