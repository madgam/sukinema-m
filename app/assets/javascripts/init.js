
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
        return false;
    });
    $('.js-modal-close').on('click', function ()
    {
        $('.js-modal').fadeOut();
        return false;
    });
}