require 'test_helper'
require 'fileutils'

class PatientZipperTest < ActiveSupport::TestCase
  setup do
    pt = FactoryBot.create(:product_test_static_result)
    patient = FactoryBot.create(:static_test_patient, bundleId: pt.bundle.id)
    patient.save
    @patients = Patient.all.to_a.select { |p| p.gender == 'F' }

    prov = Provider.default_provider

    @patients.each do |p|
      p.provider_performances << CQM::ProviderPerformance.new(provider: prov)
      p.save!
    end
  end

  test 'Should create valid html file' do
    format = :html
    filename = "pTest-#{Time.now.to_i}.html.zip"
    file = Tempfile.new(filename)
    Cypress::PatientZipper.zip(file, @patients, format)
    file.close
    count = 0
    Zip::ZipFile.foreach(file.path) do |zip_entry|
      if zip_entry.name.include?('.html') && !zip_entry.name.include?('__MACOSX')
        doc = Nokogiri::HTML(zip_entry.get_input_stream, &:strict)
        doc.at_css('head title').to_s
        count += 1
      end
    end
    File.delete(file.path)
    assert_equal @patients.count, count, 'Zip file has wrong number of records'
  end

  test 'Should create valid qrda file' do
    format = :qrda
    filename = "pTest-#{Time.now.to_i}.qrda.zip"
    file = Tempfile.new(filename)

    Cypress::PatientZipper.zip(file, @patients, format)
    file.close

    count = 0
    Zip::ZipFile.foreach(file.path) do |zip_entry|
      if zip_entry.name.include?('.xml') && !zip_entry.name.include?('__MACOSX')
        Nokogiri::XML(zip_entry.get_input_stream, &:strict)
        count += 1
      end
    end
    File.delete(file.path)
    assert_equal @patients.count, count, 'Zip file has wrong number of records'
  end

  test 'Should create valid qrda file when not associated to test' do
    @patients = Patient.where(correlation_id: nil)

    format = :qrda
    filename = "pTest-#{Time.now.to_i}.qrda.zip"
    file = Tempfile.new(filename)

    Cypress::PatientZipper.zip(file, @patients, format)
    file.close

    count = 0
    Zip::ZipFile.foreach(file.path) do |zip_entry|
      if zip_entry.name.include?('.xml') && !zip_entry.name.include?('__MACOSX')
        Nokogiri::XML(zip_entry.get_input_stream, &:strict)
        count += 1
      end
    end
    File.delete(file.path)
    assert_equal @patients.count, count, 'Zip file has wrong number of records'
  end
end
