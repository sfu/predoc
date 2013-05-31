// ...

(function ($) {

    var loadingTimeout;

    function getActiveXObject(name)
    {
        try { return new ActiveXObject(name); } catch (e) { return undefined; }
    }

    // Returns true on IE (supports ActiveX) that supports one of the PDF plugins.
    // Also returns true on any browser that doesn't support ActiveX.
    function checkIEPDFSupport()
    {
        return (!window.ActiveXObject || getActiveXObject('AcroPDF.PDF') || getActiveXObject('PDF.PdfCtrl'));
    }

    function showDocument()
    {
        // we don't need the timeout timer anymore
        clearTimeout(loadingTimeout);

        $('#viewer-messages').fadeOut();
    }

    function showTimeout()
    {
        $('#alternative').show();
        $('#alt-timeout').show();
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

        var converterPath = '/convert';

        // just abort if client is using IE that lacks PDF support
        if (!checkIEPDFSupport())
        {
            $('#alternative').show();
            $('#alt-plugin').show();
            $('#loading-indicator').hide();
            return;
        }

        // create the <iframe> to display the converted document seamlessly
        $('<iframe>')
            .attr('id', 'document')
            .attr('src', converterPath + '?source=' + encodeURIComponent($('#loading-indicator').data('viewer-source')))
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('seamless', 'seamless')
            .bind('load', showDocument)
            .appendTo('body');

        // start the timeout timer so users don't have to wait forever
        loadingTimeout = setTimeout(showTimeout, 10000);

        checkDocumentProgress();
    });

    $(window).bind('unload', function () {
        // this fixes an issue in IE10 where the document could remain stuck on screen
        $('#document').remove();
    });

})(jQuery);
