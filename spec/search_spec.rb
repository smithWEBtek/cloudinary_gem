require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Search do
  context 'unit' do
    it 'should create empty json' do
      query_hash = Cloudinary::Search.to_query
      expect(query_hash).to eq({})
    end

    it 'should always return same object in fluent interface' do
      instance = Cloudinary::Search.new
      %w(expression sort_by max_results next_cursor aggregate includes).each do |method|
        same_instance = instance.send(method, 'emptyarg')
        expect(instance).to eq(same_instance)
      end
    end

    it 'should add expression to query' do
      query = Cloudinary::Search.expression('format:jpg').to_query
      expect(query).to eq(expression: 'format:jpg')
    end

    it 'should add sort_by to query' do
      query = Cloudinary::Search.sort_by('created_at', 'asc').sort_by('updated_at', 'desc').to_query
      expect(query).to eq(sort_by: [{ 'created_at' => 'asc' }, { 'updated_at' => 'desc' }])
    end

    it 'should add max_results to query' do
      query = Cloudinary::Search.max_results('format:jpg').to_query
      expect(query).to eq(max_results: 'format:jpg')
    end

    it 'should add next_cursor to query' do
      query = Cloudinary::Search.next_cursor('format:jpg').to_query
      expect(query).to eq(next_cursor: 'format:jpg')
    end

    it 'should add facets arguments as array to query' do
      query = Cloudinary::Search.aggregate('format', 'size_category').to_query
      expect(query).to eq(aggregate: %w(format size_category))
    end

    it 'should add includes to query' do
      query = Cloudinary::Search.includes('context', 'tags').to_query
      expect(query).to eq(includes: %w(context tags))
    end
  end

  context 'integration' do
    include_context 'cleanup', TIMESTAMP_TAG
    TEST_WIDTH = rand(1000)
    TEST_TRANSFOMATION = "c_scale,w_#{TEST_WIDTH}".freeze
    prefix = "api_test_#{Time.now.to_i}"
    test_id_1 = "#{prefix}_1"
    test_id_2   = "#{prefix}_2"
    test_id_3   = "#{prefix}_3"
    before(:all) do
      Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_1, tags: [TEST_TAG, TIMESTAMP_TAG], context: 'stage=in_review')
      Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_2, tags: [TEST_TAG, TIMESTAMP_TAG], context: 'stage=new')
      Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_3, tags: [TEST_TAG, TIMESTAMP_TAG], context: 'stage=validated')
      sleep(2)
    end

    after(:all) do
      # in addition to "cleanup" context
      unless Cloudinary.config.keep_test_products
        up = Cloudinary::Api.upload_presets max_results: 500
        up['presets'].each do |u|
          tags = u['settings']['tags']
          name = u['name']
          if tags =~ /.*#{TIMESTAMP_TAG}.*/
            Cloudinary::Api.delete_upload_preset(name)
          end
        end
      end
    end
    it "should return all images tagged with #{TEST_TAG}" do
      results = Cloudinary::Search.expression("tags:#{TEST_TAG}").execute
      expect(results['resources'].count).to eq 3
    end

    it "should return resource #{test_id_1}" do
      results = Cloudinary::Search.expression("public_id:#{test_id_1}").execute
      expect(results['resources'].count).to eq 1
    end

    it 'should paginate resources limited by tag and orderd by ascending public_id' do
      results = Cloudinary::Search.max_results(1).expression("tags:#{TEST_TAG}").sort_by('public_id', 'asc').execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_1
      expect(results['total_count']).to eq 3

      results = Cloudinary::Search.max_results(1).expression("tags:#{TEST_TAG}").sort_by('public_id', 'asc').next_cursor(results['next_cursor']).execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_2
      expect(results['total_count']).to eq 3

      results = Cloudinary::Search.max_results(1).expression("tags:#{TEST_TAG}").sort_by('public_id', 'asc').next_cursor(results['next_cursor']).execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_3
      expect(results['total_count']).to eq 3

      results = Cloudinary::Search.max_results(1).expression("tags:#{TEST_TAG}").sort_by('public_id', 'asc').next_cursor(results['next_cursor']).execute
      expect(results['resources'].count).to eq 0
    end

    it 'should include context' do
      results = Cloudinary::Search.expression("tags:#{TEST_TAG}").includes('context').execute
      expect(results['resources'].count).to eq 3
      results['resources'].each do |res|
        expect(res['context'].keys).to eq ['stage']
      end
    end
    it 'should include context, tags and image_metadata' do
      results = Cloudinary::Search.expression("tags:#{TEST_TAG}").includes('context', 'tags', 'image_metadata').execute
      expect(results['resources'].count).to eq 3
      results['resources'].each do |res|
        expect(res['context'].keys).to eq ['stage']
        expect(res.key?('image_metadata')).to eq true
        expect(res['tags'].count).to eq 2
      end
    end
  end
end
