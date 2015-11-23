require 'test_helper'

describe Jarbs::Config do
  let(:config) { Jarbs::Config.new('test/fixtures/.jarbs') }

  it "can get and set keys" do
    config.set('test', 'value')
    assert_equal 'value', config.get('test')
  end

  it 'can set a value if block provided' do
    config.get('burger') do
      'whata'
    end

    assert_equal 'whata', config.get('burger')
  end

  it 'initializes self from file' do
    assert_equal 'burger', config.get('need.a')
  end

  it 'writes settings to a file' do
    config.set('newthing', 'here')
    file = JSON.parse(File.read('test/fixtures/.jarbs'))

    assert_equal 'here', file['newthing']
  end

  describe "global" do
    let(:global) { Jarbs::Config.new('test/fixtures/.global_jarbs') }

    before do
      config.stub(:global, global) do
        config.set('tester', 'ing', from_global: true)
      end
    end

    it "can get and set global options" do
      config.stub(:global, global) do
        assert_equal 'ing', config.get('tester', from_global: true)
      end
    end

    it "doesn't set the local config" do
      assert_nil config.get('tester')
    end
  end
end


