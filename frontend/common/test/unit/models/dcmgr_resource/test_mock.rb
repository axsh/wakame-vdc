require 'rubygems'
require 'test/unit'
require 'active_resource'
require 'json'
require File.expand_path('../../../../lib/models/dcmgr_resource/mock')

module Frontend
    class TestAccount < Test::Unit::TestCase
      def setup
        @mock = Frontend::Models::DcmgrResource::Mock
      end

      def teardown
      end
      
      def test_load
        @load = ['instances/list',
                 'instances/details',
                 'images/list',
                 'images/details',
                 'volumes/list',
                 'volumes/details'
                ]

        Dir.chdir('../../../../../') do
          Dir.chdir('common') do
            @load.each do |source|
              json = @mock.load(source)
              begin
                JSON.parse!(json)
                parse = true
              rescue JSON::ParserError => e
                parse = false
              end
              assert_equal(parse,true)
            end
          end
        end
      end
    end
end