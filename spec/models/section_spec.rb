require 'spec_helper'

describe Section do

  before(:each) do
    Page.delete_all
    Section.delete_all
  end

  it "uses permalink as key" do
    section = Section.new(:permalink => 'about', :title => "About Sections")
    section.save
    _section = Section.find("about")
    assert _section.eql?(section), "Section should be addressed by key"
  end

  it "doesn't allow chars other than A-Z/0-9 in permalink" do
    invalid1 = Section.new(:permalink => 'this is invalid', :title => "Invalid")
    invalid2 = Section.new(:permalink => 'this-is-invalid', :title => "Invalid Too")
    valid    = Section.new(:permalink => '123abc45ZYX', :title => "valid")
    invalid1.should_not be_valid
    invalid2.should_not be_valid
    valid.should be_valid
  end

  it "has many pages" do
    section = Section.new(:permalink => 'about', :title => "About Sections")
    section.save!
    section.pages.create(:permalink => 'page 1', position: 1, :title => 'Page One', body: 'Page one body')
    section.pages.create(:permalink => 'page 2', position: 2, :title => 'Page Two', body: 'Page two body')
    section.save!
    section.reload
    section.pages.count.should == 2
    section.pages.first.title.should == 'Page One'
  end

  it "provides banners of all section's pages in an array" do
    section = Section.create(:permalink => 'Banners', :title => "About Banners")
    p1 = section.pages.create(:permalink => 'page banner a', :title => 'Page Banner A', body: 'Page one body')
    p2 = section.pages.create(:permalink => 'page banner b', :title => 'Page Banner B', body: 'Page two body')
    banner1 = p1.create_banner( banner_file_name: 'test1.png', linked_url: 'example.com/1')
    banner2 = p2.create_banner( banner_file_name: 'test2.png', linked_url: 'example.com/2')
    banner1.save!
    banner2.save!
    p1.save!
    p2.save!
    section.save!
    Section.banners.should include(banner1,banner2)
  end

  it "sorts sections by position by default" do
    section2 = Section.create(:permalink => 'Banners', :title => "About Banners", position: 2)
    section1 = Section.create(:permalink => 'Pages', :title => "About Pages", position: 1)
    section3 = Section.create(:permalink => 'Sections', :title => "About Section", position: 3)
    Section.all.map(&:permalink).should == ['Pages', 'Banners', 'Sections']
  end

  describe  "scopes sections for top menu" do
    before(:each) do
      Section.delete_all
      Section.create( position: 1, permalink: "intop", title: "In Top", top_menu: true)
      Section.create( position: 2, permalink: "infooter", title: "In Footer", footer_menu: true)
      Section.create( position: 3, permalink: 'bothmenus', title: "Both Menus", top_menu: true, footer_menu: true)
      Section.create( position: 4, permalink: 'innomenu', title: "Listed nowhere")
      Section.count.should == 4
    end

    it "scopes sections for topmenu" do
      Section.top_menu_sections.count.should == 2
      Section.top_menu_sections.all.map(&:title).should == ["In Top", "Both Menus"]
    end

    it "scopes sections for footer" do
      Section.footer_sections.all.map(&:title).should == ["In Footer", "Both Menus"]
    end

  end
end
