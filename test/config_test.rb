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
end


