require 'minitest/autorun'
require 'sarah'

class TestSarah_00 < MiniTest::Unit::TestCase

    def test_cmethod_new
	assert_respond_to Sarah, :new
    end

    def test_new_1
	assert Sarah.new, "Failed to create new Sarah"
    end

end

# END
