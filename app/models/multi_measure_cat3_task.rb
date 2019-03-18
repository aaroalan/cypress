class MultiMeasureCat3Task < Task
  def validators
    @validators = [::Validators::MeasurePeriodValidator.new,
                   ::Validators::QrdaCat3Validator.new(product_test.expected_results, true, true, product_test.c2_test, product_test.bundle),
                   ::Validators::CMSQRDA3SchematronValidator.new(product_test.bundle.version),
                   ::Validators::ExpectedResultsValidator.new(product_test.expected_results)]
    @validators
  end

  def execute(file, user)
    te = test_executions.create!(expected_results: expected_results, artifact: Artifact.new(file: file), user_id: user)
    TestExecutionJob.perform_later(te, self, validate_reporting: product_test.c3_test)
    te.save
    te
  end

  def good_results
    cms_compatibility = product_test&.product&.c3_test
    options = { provider: product_test.patients.first.provider, submission_program: cms_compatibility, start_time: start_date, end_time: end_date }
    Qrda3R21.new(product_test.expected_results, product_test.measures, options).render
  end
end