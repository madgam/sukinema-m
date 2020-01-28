
function init()
{
    get_current_location();
}
/**
 * 
 */
function _modal_init()
{
    $('.js-modal-open').on('click', function ()
    {
        var id = $(this).attr('id');
        _return_dertail_disp(id);
        $('.js-modal').fadeIn();
        //スクロール禁止
        $('body').css('overflow', 'hidden');
    });
    $('.js-modal-close').on('click', function ()
    {
        $('.js-modal').fadeOut();
        //スクロール復帰
        $('body').css('overflow', 'auto');
        return false;
    });
}

function handleTouchMove(event)
{
    event.preventDefault();
}
