// ...

(function ($) {

    function showDocument()
    {
        $('#document').show();
        $('#viewer-messages').hide();
    }

    // IE doesn't fire the onload event in a PDF iframe. We poll for the progress as an alternative.
    // http://stackoverflow.com/questions/30005/how-do-i-fire-an-event-when-a-iframe-has-finished-loading-in-jquery
    function checkDocumentProgress()
    {
        // obtain the ready state value (or abort if unavailable)
        var readyState = document.getElementById('document').readyState;
        if (readyState == undefined) { return; }

        if (readyState == 'complete')
        {
            showDocument();
            return;
        }

        // if hasn't returned by now, poll again for progress
        setTimeout(checkDocumentProgress, 200);
    }

    $(document).ready(function () {

        var converterPath = '/documents/convert';

        // create the <iframe> to display the converted document seamlessly
        $('<iframe>')
            .attr('id', 'document')
            .attr('src', converterPath + '?source=' + encodeURIComponent($('#loading-indicator').data('viewer-source')))
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('seamless', 'seamless')
            .bind('load', showDocument)
            .hide()
            .appendTo('body');

        checkDocumentProgress();
    });

})(jQuery);
