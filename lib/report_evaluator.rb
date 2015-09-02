require 'ast'
require 'ruleset'
require 'rule'
require 'pry'

class ReportEvaluator
  include AST::Processor::Mixin

  attr_reader :report, :results, :ruleset

  def initialize(ruleset)
    @ruleset = ruleset
  end

  def call(report)
    @report = report
    @results = ruleset.rules.map { |rule| process(rule.ast) }
  end
end
