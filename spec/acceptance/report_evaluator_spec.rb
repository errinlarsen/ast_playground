require 'spec_helper'
require 'json'
require 'report_evaluator'

RSpec.describe ReportEvaluator do
  include AST::Sexp

  let(:evaluator) { ReportEvaluator.new(ruleset) }
  let(:ruleset) { Ruleset.new("Red Flags", [rule]) }
  let(:rule) { Rule.new("BMI Over 40", ast) }
  let(:ast) { test_source_ast }

  def test_source_ast
    {if: [
      {">": [
        {value: [{name: "patient"}, {name: "bmi"}]},
        {integer: 40}
      ]},
      {if: [
        {">": [
          {value: [{name: "patient"}, {name: "age"}]},
          {integer: 65}
        ]},
        {string: "BMI is over 40 and patient is over 65"},
        {string: "BMI is over 40 but patient is under 65"}
      ]},
      {string: "BMI is under 40"}
    ]}
  end

  context "generating responses for a report with a high BMI" do
    let(:report) { JSON.parse(fake_report) }

    it "responds with the appropriate format and contents" do
      expected_ast =
        s(:results, [
          s(:ruleset, s(:string, "Red Flags")),
          s(:rules, [
            s(:rule, [
              s(:name, s(:string, "BMI Over 40")),
              s(:output, s(:string, "BMI is over 40 and patient is over 65")),
              s(:explain, [
                s(:string, 'because [patient/bmi] was [>] [40]'),
                s(:string, 'because [patient/age] was [>] [65]') ]) ]) ]) ])

      expect( evaluator.call(report) ).to eq(expected_ast)
    end
  end

  context "evaluating a report with a low BMI" do
    let(:low_bmi_report) { fake_report.gsub(/"bmi": "42"/, %q["bmi": "23"]) }
    let(:report) { JSON.parse(low_bmi_report) }

    it "returns a response noting that the BMI is OK" do
      expected_ast =
        s(:results, [
          s(:ruleset, s(:string, "Red Flags")),
          s(:rules, [
            s(:rule, [
              s(:name, s(:string, "BMI Over 40")),
              s(:output, s(:string, "BMI is under 40")),
              s(:explain, [
                s(:string, 'because [patient/bmi] was not [>] [40]') ]) ]) ]) ])

      expect( evaluator.call(report) ).to eq(expected_ast)
    end
  end

  context "evaluating an invalid report" do
    let(:report) { JSON.parse('["gimlet"]') }

    it "returns an empty response" do
      expect( evaluator.call(report) ).to eq(s(:empty))
    end
  end

  def fake_report
    <<-END_JSON
    {
      "date_of_procedure": "2015-06-16",
      "status": "work_in_progress",
      "patient": {
        "id": 3226531,
        "age": 71,
        "name": "JOHN DOE",
        "bmi": "42"
      },
      "added_procedures": [
        {
          "description": "Excisional debridement into subcutaneous tissue; first 20 sq cm",
          "identifier": "11042"
        }
      ],
      "answers": [
        {
          "question_id": 655,
          "value": "WALCOTT, GEORGE D",
          "template": null,
          "attribute": "attending_physician"
        }
      ]
    }
    END_JSON
  end
end
