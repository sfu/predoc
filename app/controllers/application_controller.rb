require 'docsplit'

class ApplicationController < ActionController::Base
  protect_from_forgery

  # Indicates whether the application has the necessary tools to convert documents.
  def can_convert?
    extractor = Docsplit::PdfExtractor.new
    extractor.libre_office? || extractor.open_office? rescue false
  end
end
