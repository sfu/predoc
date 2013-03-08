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
                // hide the messages when the document is loaded
                $('#viewer-messages').hide();
            })
            .appendTo('body');

    });

})(jQuery);
