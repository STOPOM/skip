# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

module BoardEntriesHelper

  # ネスト構造のコメントを生成する
  def render_nest_comment comment, level, checked_on
    result = ""
    comment.children.each do |child_comment|
      result << render(:partial => "board_entries/board_entry_comment", :locals => { :comment => child_comment, :level => level, :checked_on => checked_on })
    end
    result
  end

  # 記事を書いた人かどうか
  # TODO BoardEntry#writer?と重複してる。無くしたい
  def writer? comment, user_id
    user_id == comment.user_id
  end

  # 記事を書いた人及びコメントを書いた人かどうか
  # TODO BoardEntryComment#writer?となるようにしたい。
  def comment_writer? comment, user_id
    writer?(comment, user_id) || (comment.board_entry.user_id == user_id)
  end

<<<<<<< HEAD:app/helpers/board_entries_helper.rb
=======
  def date_with_icon date
    formated_date = "[ #{date.strftime('%Y/%m/%d-%H:%M')} ]"
    if Time.now - date < 12.hour
      "#{formated_date} #{icon_tag :emoticon_happy, :alt => _('[12時間以内のコメント]'), :title => _('[12時間以内のコメント]')}"
    elsif Time.now - date < 24.hour
      "#{formated_date} #{icon_tag :emoticon_smile, :alt => _('[24時間以内のコメント]'), :title => _('[24時間以内のコメント]')}"
    else
      formated_date
    end
  end

>>>>>>> for_i18n:app/helpers/board_entries_helper.rb
  def link_to_write_place owner
    name = write_place_name(owner)
    unless name.blank?
      link_to name, write_place_url(owner)
    else
      ''
    end
  end

  # edit_controllerからも呼ばれているため、ERBクラスを指定してサニタイズする
  def write_place_name owner
    if owner
<<<<<<< HEAD:app/helpers/board_entries_helper.rb
      return "#{ERB::Util.html_escape(owner.name)}のブログ" if owner.class == User
      return "#{ERB::Util.html_escape(owner.name)}の掲示板" if owner.class == Group
=======
      return _("%s's Blog") % owner.name if owner.class == User
      return _("BBS of %s") % owner.name if owner.class == Group
>>>>>>> for_i18n:app/helpers/board_entries_helper.rb
    end
    ''
  end

  def write_place_url owner
    if owner
      return url_for(:controller => 'user', :action => 'blog', :uid => owner.uid, :archive => 'all') if owner.class == User
      return url_for(:controller => 'group', :action => 'bbs', :gid => owner.gid) if owner.class == Group
    end
  end

  def comment_title_class current_user, comment, checked_on
    if current_user.id == comment.user_id
      'title current_user'
    elsif checked_on && checked_on <= comment.updated_on
      'title other_user not_read'
    else
      'title other_user read'
    end
  end

  def icon_with_information current_user, comment, checked_on
    text = ''
    text << '[新着]' if Time.now - comment.created_on < 24.hour
    text << '[未読]' if current_user.id != comment.user_id && (checked_on && checked_on <= comment.updated_on)
    icon_type = Time.now - comment.created_on < 12.hour ? :emoticon_happy : :emoticon_smile
    text.blank? ? "" : "#{icon_tag icon_type}#{text}"
  end
end
