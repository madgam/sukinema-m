
var sort_flg = false;
var $list = $('#data').data('list-id');
var count = $list.length;

// $(function ()
$('#current_longitude').ready(function()
{
	var _r_list = [];
	if (!sort_flg)
	{
		setTimeout(function ()
		{
			_r_list = sort('sort_1');
		}, 200);
	}
	setTimeout(function ()
	{
		_make_list(_r_list);
	}, 500);
	$('.sort_link').on('click', function ()
	{
		var sort_id = $(this).attr('id');
		var _r_list = sort(sort_id);
		_make_list(_r_list);
		sort_flg = true;
		$('.sort_link').addClass('off');
		$('#' + sort_id).removeClass('off');
	});
});

/**
 * 
 * @param {*} list
 */
function _make_list(list)
{
	var html = '';
	var _count = list.length;
	var _div_end = '</div>';
	if (_count > 50)
	{
		_count = 50;
	}
	$('#list').html('');
	for (var i = 0; i < _count; i++)
	{
		html += '<div class="card">';
		html += '<a class="link js-modal-open" id="' + list[i].index + '" href="#"></a>';
		html += '<div class="image_content">';
		var distance = list[i].distance;
		if (distance == 0)
		{
			distance = '-';
		} else
		{
			distance += '<span><small>km</small></span>';
		}
		html += '<div class="place">' + distance + _div_end;
		var ratingNum = list[i].review;
		var ratingStarClass = '';
		if (ratingNum > 0)
		{
			var _r_rating_num = ratingNum * 10;
			ratingStarClass = String(_r_rating_num - _r_rating_num % 5);
			ratingStarClass = '000' + ratingStarClass;
		} else
		{
			ratingStarClass = String(ratingNum).replace('.', '');
			ratingStarClass = '000' + ratingStarClass;
		}
		html += '<div class="rating rating_' + ratingStarClass.slice(-2) + '">';
		html += '<div class="rating_num">' + ratingNum + _div_end;
		html += '<div class="rating_star">' + _div_end + _div_end;
		html += '<div class="img_box">';
		var poster = list[i].drop_path;
		if (!poster)
		{
			poster = 'assets/noimages.png';
		}
		html += '<img src="' + poster + '"/>' + _div_end + _div_end;
		html += '<div class="content">';
		html += '<div class="left_text">';
		html += '<span>上映まで</span>';
		html += '<div class="strong time">' + list[i].time + '分' + _div_end + _div_end;
		html += '<div class="right_text">' + list[i].title + _div_end + _div_end + _div_end + _div_end;
	}
	$('#list').append(html);
	_modal_init();
}

/**
 * 
 * @param {*} id 
 */
function _return_dertail_disp(id)
{
	var now = new Date();
	var hour_num = now.getHours();
	var hour = '0' + String(hour_num);
	var minute_num = now.getMinutes();
	var minute = '0' + String(minute_num);
	var current_time = hour.slice(-2) + minute.slice(-2);
	$list.forEach(function (movie)
	{
		if (movie.index == id)
		{
			var title = movie.title;
			var theater = movie.theater;
			var description = movie.description;
			var link = movie.link;
			var release_date = movie.release_date;
			var poster_path = movie.drop_path;
			var all_time = movie.all_time;
			$('.mo_title').html(title);
			if (!release_date)
			{
				release_date = '-';
			}
			$('.mo_date').html(release_date);
			$('.mo_place').html(theater);
			$('.mo_place').attr('href', link);
			var all_time_arry = all_time.trim().replace(/&nbsp;/g, '').split(' / ');
			var result_time_array = '';
			all_time_arry.forEach(function (time)
			{
				var time_only_num = time.replace(':', '');
				if (time_only_num.length != 4)
				{
					time_only_num = '0' + time_only_num;
				}
				if (time_only_num < current_time)
				{
					return;
				}
				result_time_array += time;
				result_time_array += ',';
			});
			$('.mo_time').html(result_time_array.slice(0,-1));
			if (!description)
			{
				description = '説明文なし';
			}
			$('.mo_txt').html(description);
			$('#mo_link').attr('href', link);
			if (!poster_path)
			{
				poster_path = 'assets/noimages.png';
			} else
			{
				var poster_id = movie.poster_id;
				poster_path = `https://image.tmdb.org/t/p/w300_and_h450_face${ poster_id }`;
			}
			$('.mo_img img').attr('src', poster_path);
		}
	});
}

/**
 * 
 */
function _get_movie_list()
{
	_movie_list = [];
	for (var i = 0; i < count; i++)
	{
		var _list = {};
		_list['index'] = $list[i].index;
		_list['title'] = $list[i].title;
		_list['theater'] = $list[i].theater;
		_list['latitude'] = $list[i].latitude;
		_list['longitude'] = $list[i].longitude;
		_list['description'] = $list[i].description;
		_list['link'] = $list[i].link;
		_list['time'] = $list[i].time;
		_list['all_time'] = $list[i].all_time;
		_list['review'] = $list[i].review;
		_list['release_date'] = $list[i].release_date;
		_list['drop_path'] = $list[i].drop_path;
		_list['poster_id'] = $list[i].poster_id;
		var current_latitude = $('#current_latitude').html();
		var current_longitude = $('#current_longitude').html();
		var latitude = $list[i].latitude;
		var longitude = $list[i].longitude;
		var distance = get_distance(
			current_latitude,
			current_longitude,
			latitude,
			longitude
		);
		_list['distance'] = distance;
		_movie_list.push(_list);
	}
	return _movie_list
}