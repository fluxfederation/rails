require 'abstract_unit'
require 'active_support/inflector'

class InflectorLocalityFallbackTest < ActiveSupport::TestCase
  def setup
    # Dups the singleton before each test, restoring the original inflections later.
    #
    # This helper is implemented by setting @__instance__ because in some tests
    # there are module functions that access ActiveSupport::Inflector.inflections,
    # so we need to replace the singleton itself.
    #
    # This cannot be in the same file as the other inflector tests as changing
    # the I18n backend effects all later tests.
    @original_inflections = ActiveSupport::Inflector::Inflections.instance_variable_get(:@__instance__)[:en]
    ActiveSupport::Inflector::Inflections.instance_variable_set(:@__instance__, en: @original_inflections.dup)
    I18n.backend.class.include(I18n::Backend::Fallbacks)
  end

  def teardown
    ActiveSupport::Inflector::Inflections.instance_variable_set(:@__instance__, en: @original_inflections)
  end

  def test_inflector_locality_fallback
    ActiveSupport::Inflector.inflections(:es) do |inflect|
      inflect.plural(/$/, 's')
      inflect.plural(/z$/i, 'ces')

      inflect.singular(/s$/, '')
      inflect.singular(/es$/, '')

      inflect.irregular('el', 'los')

      inflect.uncountable('agua')
    end

    assert ActiveSupport::Inflector.inflections(:'es-AR').plurals.empty?
    assert ActiveSupport::Inflector.inflections(:'es-AR').singulars.empty?
    assert ActiveSupport::Inflector.inflections(:'es-AR').uncountables.empty?

    assert_equal('hijos', 'hijo'.pluralize(:'es-AR'))
    assert_equal('luces', 'luz'.pluralize(:'es-AR'))
    assert_equal('hijos', 'hijo'.pluralize(:es))
    assert_equal('luces', 'luz'.pluralize(:es))
    assert_equal('luzs', 'luz'.pluralize)

    assert_equal('sociedad', 'sociedades'.singularize(:'es-AR'))
    assert_equal('sociedad', 'sociedades'.singularize(:es))
    assert_equal('sociedade', 'sociedades'.singularize)

    assert_equal('los', 'el'.pluralize(:'es-AR'))
    assert_equal('los', 'el'.pluralize(:es))
    assert_equal('els', 'el'.pluralize)

    assert_equal('agua', 'agua'.pluralize(:'es-AR'))
    assert_equal('agua', 'agua'.pluralize(:es))
    assert_equal('aguas', 'agua'.pluralize)
  end
end
