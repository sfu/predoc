require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest

  def assert_pdf_sent
    assert_response :success
    assert_equal(@response.headers['Content-Type'], 'application/pdf')
  end

  ###
  # TEST ROUTE/PARAMETER HANDLING
  ###

  def test_handle_missing_params
    get convert_url
    assert_response :success
    assert_template(:error)
    assert_nil assigns(:source)
  end

  def test_assign_source_param
    source = 'just a test'
    get convert_url, params: { url: source }
    assert_equal(assigns(:source), source)
  end

  ###
  # TEST CONVERSION OF OFFICE DOCUMENTS
  ###

  def test_convert_doc
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:doc] }
    assert_pdf_sent
  end

  def test_convert_xls
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:xls] }
    assert_pdf_sent
  end

  def test_convert_ppt
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:ppt] }
    assert_pdf_sent
  end

  def test_convert_docx
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:docx] }
    assert_pdf_sent
  end

  def test_convert_xlsx
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:xlsx] }
    assert_pdf_sent
  end

  def test_convert_pptx
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:pptx] }
    assert_pdf_sent
  end

  ###
  # TEST CONVERSION OF OTHER DOCUMENTS
  ###

  def test_convert_txt
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:txt] }
    assert_pdf_sent
  end

  def test_convert_rtf
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:rtf] }
    assert_pdf_sent
  end

  def test_convert_html
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:html] }
    assert_pdf_sent
  end

  # TODO: test images (e.g. PNG, GIF, JPEG)

  def test_convert_video
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:mp4] }
    assert_response :success
    assert_template(:error)
  end

  def test_convert_fake_file
    get convert_url, params: { url: Predoc::TestConfig::FIXTURE_URLS[:fake] }
    assert_response :success
    assert_template(:error)
  end

  # TODO: test whether it actually caches files
  # TODO: test whether PDF pass-through works

end
