(function ($) {

    $(document).ready(function () {

        var converterPath = '/documents/convert';

        // create the <iframe> to display the converted document seamlessly
        $('<iframe>')
            .attr('src', converterPath + '?source=' + encodeURIComponent($('#loading-indicator').data('viewer-source')))
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('seamless', 'seamless')
            .bind('load', function () {
                // show document when loaded, and hide the loading messages
                $(this).show();
                $('#viewer-messages').hide();
            })
            .hide()
            .appendTo('body');

    });

})(jQuery);
