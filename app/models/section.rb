# -*- encoding : utf-8 -*-
class Section

  include Mongoid::Document
  include Mongoid::Timestamps

  key                     :permalink
  validates_presence_of   :permalink
  validates_uniqueness_of :permalink
  validates_format_of     :permalink, :with => VALIDATE_PERMALINK_REGEX, :message => I18n.t(:numbers_and_letters_only)

  field :title, type: String, :localize => true
  validates_presence_of :title
  
  field :body, type: String, :localize => true
  field :preview_length, type: Integer
  validates :preview_length, :numericality => { :only_integer => true, :greater_than => 3 }, :allow_nil => true

  field :position, type: Integer, default: 0
  default_scope asc(:position)

  has_many  :pages, :dependent => :nullify

  def preview_length_or_default
    self.preview_length || Settings.default_preview_length || 300
  end

  def self.banners
    banners = []
    self.only(:pages).each do |section|
      section.pages.where( :"banner.neq" => nil ).each do |page|
        banners << page.banner
      end
    end
    banners
  end

end