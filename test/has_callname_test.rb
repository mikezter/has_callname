require File.join(File.dirname(__FILE__), 'test_helper')

class Thing < ActiveRecord::Base
  has_callname :filters => ['muh', /gmbh\Z/ ]
  def before_create
    self.something='it is!'
  end
  
  def method_missing(m, *args)
    self.something = 'method missed'
  end
  
end

class Foo < ActiveRecord::Base
  set_table_name "things"
  has_callname :name
end



class HasCallnameTest < ActiveSupport::TestCase
  test "extends ActiveRecord with Class Method has_callname" do
    assert ActiveRecord::Base.respond_to?( 'has_callname')
  end
  
  test "callname is generated before_create" do
    thing = Thing.create!(:name => 'My first Thing')
    assert_equal 'my-first-thing', thing.read_attribute( :callname)
  end
  
  test "a Thing has a proper callname" do
    thing = Thing.create!(:name => 'My second Thing')
    assert_equal 'my-second-thing', thing.callname
  end
  
  test "the Things callname gets saved to the database" do
    thing = Thing.create!(:name => 'My third Thing')
    assert_equal 'my-third-thing', thing.callname
    assert_equal thing, Thing.find(:first, :conditions => {:callname => 'my-third-thing'})
  end
  
  test "find_by_callname should return a Thing or raise RecordNotFound" do
    thing = Thing.create!(:name => 'My forth Thing')
    thing.callname
    assert_equal thing, Thing.find_by_callname('my-forth-thing')
    assert_raises(ActiveRecord::RecordNotFound) { Thing.find_by_callname('no-thing') }
  end
  
  test "callname is unique and counter is increased" do
    thing = Thing.create!(:name => 'My unique Thing')
    thing2 = Thing.create!(:name => 'My unique Thing')
    assert thing2.callname.match(/-\d+\Z/i), thing2.callname
  end
  
  test "replaces umlauts correct" do
    thing = Thing.create!(:name => 'This has Umlauts: äöü and uppercase ÄÖÜ and beißt')
    assert_equal 'this-has-umlauts-aeoeue-and-uppercase-aeoeue-and-beisst', thing.callname, thing.name
  end
  
  test "filters additional filters" do
    thing = Thing.create!(:name => 'This muh will be filtered')
    assert !thing.callname.include?('muh')
    assert_equal 'this-will-be-filtered', thing.callname
  end
  
  test "filters additional regex filters" do
    thing = Thing.create!(:name => 'gmbh at the beginning is ok GmbH')
    assert !thing.callname.include?('GmbH')
    assert_equal 'gmbh-at-the-beginning-is-ok', thing.callname
  end
  
  test "name is not altered" do
    thing = Thing.create!(:name => 'äöü')
    thing.callname
    thing.save
    assert_equal 'äöü', thing.name
  end
  
  test "method_missing is called" do
    thing = Thing.create!(:name => 'My missing Thing')
    t = Thing.find_by_name 'My missing Thing' 
    assert_not_nil t
    t.missing_method_of_thing
    assert_equal 'method missed', t.something
  end
  
  test "before_create is called" do
    thing = Thing.create!(:name => 'My unique Thing')
    assert_equal 'it is!', thing.something
  end
  
  test "does not add counter on similar callnames" do
    t1 = Thing.create!(:name => 'This begins like the other')
    t2 = Thing.create!(:name => 'This begins like the one')
    assert_nil t2.callname.match(/-\d+$/i)
  end
  
  test "works with one column" do
    foo = Foo.create!(:name => 'Name with spaces and Ümläutß')
    assert_equal 'name-with-spaces-and-uemlaeutss', foo.name
    foo = Foo.create!(:name => 'Name with spaces and Ümläutß')
    assert_equal 'name-with-spaces-and-uemlaeutss-2', foo.name
  end
  
end
