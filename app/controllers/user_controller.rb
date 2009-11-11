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

class UserController < ApplicationController
  include UserHelper

  before_filter :load_user, :setup_layout

  # tab_menu
  def show
    # 紹介してくれた人一覧
    @against_chains = @user.against_chains.order_new.limit(5)

    # 他の人からみた・・・
    @tags = BookmarkComment.get_tagcloud_tags @user.get_postit_url
  end

  # tab_menu
  def blog
    options = { :symbol => "uid:" + @user.uid }
    setup_blog_left_box options

    # 右側
    if params[:category] or params[:keyword] or params[:archive] or params[:type]
      options[:category] = params[:category]
      options[:keyword] = params[:keyword]

      find_params = BoardEntry.make_conditions(login_user_symbols, options)

      unless (@year = ERB::Util.html_escape(params[:year])).blank? or (@month = ERB::Util.html_escape(params[:month])).blank?
        find_params[:conditions][0] << " and YEAR(date) = ? and MONTH(date) = ?"
        find_params[:conditions] << @year << @month
      end

      @entries = BoardEntry.scoped(
        :conditions => find_params[:conditions],
        :include => find_params[:include] | [ :user, :state ]
      ).order_sort_type(params[:sort_type]).aim_type(params[:type]).paginate(:page => params[:page], :per_page => 20)

      if @entries.empty?
        flash.now[:notice] = _('No matching entries found.')
      end
    else
      if entry_id = params[:entry_id]
        unless entry = BoardEntry.find_by_id(entry_id)
          flash.now[:notice] = _('There are no entries posted.')
          return
        end
        options[:id] = entry_id
      end
      find_params = BoardEntry.make_conditions(login_user_symbols, options)
      @entry = BoardEntry.scoped(
         :conditions => find_params[:conditions],
         :include => find_params[:include] | [ :user, :board_entry_comments, :state ]
      ).order_new.first
      if @entry
        @checked_on = @entry.accessed(current_user.id).checked_on
        @prev_entry, @next_entry = @entry.get_around_entry(login_user_symbols)
        @editable = @entry.editable?(login_user_symbols, session[:user_id], session[:user_symbol], login_user_groups)
        @tb_entries = @entry.trackback_entries(current_user.id, login_user_symbols)
        @to_tb_entries = @entry.to_trackback_entries(current_user.id, login_user_symbols)
        @title += " - " + @entry.title

        @entry_accesses =  EntryAccess.find_by_entry_id @entry.id
        @total_count = @entry.state.access_count
        bookmark = Bookmark.find(:first, :conditions =>["url = ?", "/page/"+@entry.id.to_s])
        @bookmark_comments_count = bookmark ? bookmark.bookmark_comments_count : 0
      else
        flash.now[:notice] = options[:id] ? _('You are not allowed to see the page.') : _('There are no entries posted.')
      end
    end
  end

  # tab_menu
  def social
    @menu = params[:menu] || "social_chain"
    partial_name = @menu

    # contents_left -> social_tags
    @tags = BookmarkComment.get_tagcloud_tags @user.get_postit_url

    # contens_right
    case @menu
    when "social_chain"
      prepare_chain
    when "social_chain_against"
      prepare_chain true
      partial_name = "social_chain"
    when "social_postit"
      prepare_postit
    else
      render_404 and return
    end

    render :partial => partial_name, :layout => "layout"
  end

  # tab_menu
  def group
    @group_counts, @total_count = Group.count_by_category(@user)
    @group_categories = GroupCategory.all

    @groups = @user.groups.active.partial_match_name_or_description(params[:keyword]).
      categorized(params[:group_category_id]).order_by_type(params[:sort_type]).
      paginate(:page => params[:page], :per_page => 50)

    flash.now[:notice] = _('No matching groups found.') if @groups.empty?
  end

private
  def setup_layout
    @title = user_title @user
    @main_menu = user_main_menu @user
    @tab_menu_option = tab_menu_option
  end

  def tab_menu_option
    { :uid => @user.uid }
  end

  def redirect_to_index
    redirect_to :action => 'show', :uid => @user.uid
  end

  def setup_blog_left_box options
    find_params = BoardEntry.make_conditions(login_user_symbols, options)
    # カテゴリ
    @categories = BoardEntry.get_category_words(find_params)

    # 月毎のアーカイブ
    @month_archives = BoardEntry.find(:all,
                                      :select => "YEAR(date) as year, MONTH(date) as month, count(distinct board_entries.id) as count",
                                      :conditions=> find_params[:conditions],
                                      :group => "year, month",
                                      :order => "year desc, month desc",
                                      :joins => "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id")
  end

  def prepare_chain against = false
    unless against
      left_key, right_key = "to_user_id", "from_user_id"
    else
      left_key, right_key = "from_user_id", "to_user_id"
    end

    @chains = Chain.scoped(:conditions => [left_key + " = ?", @user.id]).order_new.paginate(:page => params[:page], :per_page => 5)

    user_ids = @chains.inject([]) {|result, chain| result << chain.send(right_key) }
    against_chains = Chain.find(:all, :conditions =>[left_key + " in (?) and " + right_key + " = ?", user_ids, @user.id]) if user_ids.size > 0
    against_chains ||= []
    messages = against_chains.inject({}) {|result, chain| result ||= {}; result[chain.send(left_key)] = chain.comment; result }

    @result = []
    @chains.each do |chain|
      @result << { :from_user => chain.from_user,
        :from_message => chain.comment,
        :to_user => chain.to_user,
        :counter_message => messages[chain.send(right_key)] || ""
      }
    end

    flash.now[:notice] = _('There are no introductions.') if @chains.empty?
  end

  def prepare_postit
    join_state =  "left join bookmark_comment_tags on bookmark_comments.id = bookmark_comment_tags.bookmark_comment_id "
    join_state << "left join tags on tags.id = bookmark_comment_tags.tag_id "

    conditions = []
    conditions[0] = "bookmarks.url = ? "
    conditions << @user.get_postit_url
    if params[:selected_tag]
      conditions[0] << " and tags.name = ?"
      conditions << params[:selected_tag]
    end
    @postits = BookmarkComment.find(:all,
                                    :conditions => conditions,
                                    :order => "bookmark_comments.updated_on DESC",
                                    :joins => join_state,
                                    :include => [ :bookmark, :user ])
    unless @postits && @postits.size > 0
      flash.now[:notice] = _('You have no bookmarks currently.')
    end
  end

end
