class PagePresenter < BasePresenter

  presents :page

  def title
    page.title || translate_link
  end

  def created_at
    I18n.l( page.created_at.localtime, format: :short )
  end

  def body
    interpret (page.body||translate_link)
  end

  def body_snippet _body_snippet
    if _body_snippet == page.body
      interpret( _body_snippet || translate_link )
    elsif _body_snippet
      _txt = ""
      _txt = title if Settings.supress_page_title == true
      _txt += strip_tags _body_snippet
      _txt += "<div class='clear-both'></div>"
      _txt.html_safe
    else
      translate_link
    end
  end

  def banner_preview
    if page.banner_exist?
      image_tag page.banner.banner.url(:preview), class: 'pull-right banner-preview' 
    end
  end

private
  def translate_link
    link_to( t(:please_translate_to, :lang => I18n.locale), edit_page_path(page) )
  end

end