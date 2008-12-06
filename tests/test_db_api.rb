$LOAD_PATH[0,0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'mongo'
require 'test/unit'

# NOTE: assumes Mongo is running
class DBAPITest < Test::Unit::TestCase

  def setup
    host = ENV['HOST'] || ENV['host'] || 'localhost'
    port = ENV['PORT'] || ENV['port'] || 27017
    @db = XGen::Mongo::Driver::Mongo.new(host, port).db('ruby-mongo-test')
    @coll = @db.collection('test')
    @coll.clear
    @coll.insert('a' => 1)      # collection not created until it's used
    @coll_full_name = 'ruby-mongo-test.test'
  end

  def teardown
    @coll.clear unless @db.socket.closed?
  end

  def test_clear
    assert_equal 1, @coll.count
    @coll.clear
    assert_equal 0, @coll.count
  end

  def test_insert
    @coll.insert('a' => 2)
    @coll.insert('b' => 3)

    assert_equal 3, @coll.count
    docs = @coll.find().collect
    assert_equal 3, docs.length
    assert docs.include?('a' => 1)
    assert docs.include?('a' => 2)
    assert docs.include?('b' => 3)
  end

  def test_close
    @db.close
    assert @db.socket.closed?
    begin
      @coll.insert('a' => 1)
      fail "expected IOError exception"
    rescue IOError => ex
      assert_match /closed stream/, ex.to_s
    end
  end

  def test_drop_collection
    assert @db.drop_collection(@coll.name), "drop of collection #{@coll.name} failed"
    assert !@db.collection_names.include?(@coll_full_name)
  end

  def test_collection_names
    names = @db.collection_names
    assert names.length >= 1
    assert names.include?(@coll_full_name)

    coll2 = @db.collection('test2')
    coll2.insert('a' => 1)      # collection not created until it's used
    names = @db.collection_names
    assert names.length >= 2
    assert names.include?(@coll_full_name)
    assert names.include?('ruby-mongo-test.test2')
  ensure
    @db.drop_collection('test2')
  end

  def test_collections_info
    cursor = @db.collections_info
    rows = cursor.collect
    assert rows.length >= 1
    row = rows.detect { |r| r['name'] == @coll_full_name }
    assert_not_nil row
    assert_equal @coll.name, row['options']['create']
  end

  def test_full_coll_name
    assert_equal @coll_full_name, @db.full_coll_name(@coll.name)
  end

# FIXME
#   def test_index_information
#     list = @db.index_information(@coll.name)
#     assert_equal 0, list.length

#     @db.create_index(@coll, 'index_name', {'a' => 1})
#     $stderr.puts @db.create_index(@coll, 'index_name', {'a' => 1}).to_s # DEBUG
#     list = @db.index_information(@coll.name)
#     $stderr.puts "list = #{list.inspect}" # DEBUG
#     assert_equal 1, list.length
#   end
end
