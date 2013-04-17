require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase

  def assert_pdf_sent
    assert_response :success
    assert_equal(@response.headers['Content-Type'], 'application/pdf')
  end

  ###
  # TEST ROUTE/PARAMETER HANDLING
  ###

  test 'should handle missing parameters' do
    get :convert
    assert_response :success
    assert_template(:error)
    assert_nil assigns(:source)
  end

  test 'should assign the source parameter properly' do
    source = 'just a test'
    get :convert, source: source
    assert_equal(assigns(:source), source)
  end

  ###
  # TEST CONVERSION OF OFFICE DOCUMENTS
  ###

  test 'should convert a Word document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:doc]
    assert_pdf_sent
  end

  test 'should convert an Excel document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:xls]
    assert_pdf_sent
  end

  test 'should convert a PowerPoint document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:ppt]
    assert_pdf_sent
  end

  test 'should convert an OOXML Word document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:docx]
    assert_pdf_sent
  end

  test 'should convert an OOXML Excel document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:xlsx]
    assert_pdf_sent
  end

  test 'should convert an OOXML PowerPoint document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:pptx]
    assert_pdf_sent
  end

  ###
  # TEST CONVERSION OF OTHER DOCUMENTS
  ###

  test 'should convert a plain text document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:txt]
    assert_pdf_sent
  end

  test 'should convert a rich text document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:rtf]
    assert_pdf_sent
  end

  test 'should convert an HTML document' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:html]
    assert_pdf_sent
  end

  # TODO: test images (e.g. PNG, GIF, JPEG)

  test 'should handle a non-existent file' do
    get :convert, source: Predoc::TestConfig::FIXTURE_URLS[:fake]
    assert_response :success
    assert_template(:error)
  end

  # TODO: test whether it actually caches files
  # TODO: test whether PDF pass-through works

end
