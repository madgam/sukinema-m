
/**
 * 
 * @param {*} id 
 */
function sort(id)
{
    var _r_list = [];
    switch (id)
    {
        case 'sort_1':
            // 時間順でソート
            _r_list = _time_sort('time');
            break;
        case 'sort_2':
            // 距離順でソート
            _r_list = _distance_sort('distance');
            break;
        case 'sort_3':
            // レビューでソート
            _r_list = _review_sort('review');
            break;
    }
    return _r_list;
} 

/**
 * 
 * @param {*} key 
 */
function _time_sort(key)
{
    var _r_list = get_movie_list();
    _r_list.sort(function (a, b)
    {
        var _a_time = '0000' + String(a.time);
        var _b_time = '0000' + String(b.time);
        if (_a_time.slice(-4) > _b_time.slice(-4)) return 1;
        if (_a_time.slice(-4) < _b_time.slice(-4)) return - 1;
        return 0;
    });
    return _r_list;
}

function _distance_sort(key)
{
    var _r_list = get_movie_list();
    _r_list.sort(function (a, b)
    {
        var _a_distance = a[key] == 0.0 ? '9999' : '0000' + a.distance * 10;
        var _b_distance = b[key] == 0.0 ? '9999' : '0000' + b.distance * 10;
        var _a_time = '0000' + String(a.time);
        var _b_time = '0000' + String(b.time);
        if (_a_distance.slice(-4) > _b_distance.slice(-4)) return 1;
        if (_a_distance.slice(-4) < _b_distance.slice(-4)) return -1;
        if (_a_time.slice(-4) > _b_time.slice(-4)) return 1;
        if (_a_time.slice(-4) < _b_time.slice(-4)) return - 1;
        return 0;
    });
    return _r_list;
}
/**
 * 
 * @param {*} key 
 */
function _review_sort(key)
{
    var _r_list = get_movie_list();
    _r_list.sort(function (a, b)
    {
        var _a_review = '000' + a.review * 10;
        var _b_review = '000' + b.review * 10;
        var _a_title = a.title;
        var _b_title = b.title;
        if (_a_review.slice(-2) > _b_review.slice(-2)) return -1;
        if (_a_review.slice(-2) < _b_review.slice(-2)) return 1;
        if (_a_title > _b_title) return 1;
        if (_a_title < _b_title) return -1;
        return 0;
    });
    return _r_list;
}
