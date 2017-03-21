class Cloudinary::Search
  def initialize
    @query_hash = {}
  end

  ## implicit execute and delegate method to the result hash
  def method_missing(method_name, *arguments, &block)
    result = self.execute
    return result.send(method_name,*arguments)
  end

  ## implicitly generate an instance delegate the method
  def self.method_missing(method_name, *arguments, &block)
    instance = self.new
    instance.send(method_name,*arguments)
  end

  def expression(value)
    @query_hash[:expression]= value
    self
  end

  def sort_by(*values)
    @query_hash[:sort_by]= values
    self
  end

  def max_results(value)
    @query_hash[:max_results]= value
    self
  end
  def next_cursor(value)
    @query_hash[:next_cursor]= value
    self
  end
  def facets(*values)
    @query_hash[:facets]= values
    self
  end

  def includes(*values)
    @query_hash[:includes]= values
    self
  end

  def to_query
    @query_hash
  end

  def execute
    uri = "resources/search"
    return Cloudinary::Api.call_api(:post,uri,to_query,{})
  end
end



