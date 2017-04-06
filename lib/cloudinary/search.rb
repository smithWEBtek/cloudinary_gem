class Cloudinary::Search
  def initialize
    @query_hash = {
      :sort_by    => [],
      :aggregate  => [],
      :include   => []
    }
  end

  ## implicitly generate an instance delegate the method
  def self.method_missing(method_name, *arguments)
    instance = new
    instance.send(method_name, *arguments)
  end

  def expression(value)
    @query_hash[:expression] = value
    self
  end

  def max_results(value)
    @query_hash[:max_results] = value
    self
  end

  def next_cursor(value)
    @query_hash[:next_cursor] = value
    self
  end

  def sort_by(field_name, dir = 'desc')
    @query_hash[:sort_by].push(field_name => dir)
    self
  end

  def aggregate(*values)
    @query_hash[:aggregate].push(*values)
    self
  end

  def include(*values)
    @query_hash[:include].push(*values)
    self
  end

  def to_query
    @query_hash.select { |_, value| !value.nil? && !(value.is_a?(Array) && value.empty?) }
  end

  def execute
    uri = 'resources/search'
    Cloudinary::Api.call_api(:post, uri, to_query, :content_type=> :json)
  end
end
