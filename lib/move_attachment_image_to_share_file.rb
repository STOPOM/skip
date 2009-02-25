# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class MoveAttachmentImageToShareFile < BatchBase
  def self.execute options = {}

    # 共有ファイルのディレクトリリネーム
    rename_uid_dir
    rename_gid_dir

    # 記事の添付画像の移行
    base_path = "#{INITIAL_SETTINGS['image_path']}/board_entries"
    ShareFile.transaction do
      Dir.foreach(base_path) do |user_dir_name|
        next if (user_dir_name == '.' || user_dir_name == '..')
        user_dir_path = "#{base_path}/#{user_dir_name}"
        Dir.foreach(user_dir_path) do |filename|
          next if (filename == '.' || filename == '..')
          next unless (share_file = new_share_file(user_dir_name, filename))

          # 実ファイルコピー
          src = "#{user_dir_path}/#{filename}"
          dest = share_file.full_path
          FileUtils.cp src, dest

          # DBレコード作成
          share_file.save_without_validation!
        end
      end
    end
  end

  # 共有ファイルの実体ファイル配備ディレクトリuidをidに変換
  def self.rename_uid_dir
    user_base_path = "#{INITIAL_SETTINGS['share_file_path']}/user"
    return unless File.exist?(user_base_path)
    Dir.foreach(user_base_path) do |uid|
      next if (uid == '.' || uid == '..')
      src = "#{user_base_path}/#{uid}"
      if user = User.find_by_uid(uid)
        dest = "#{user_base_path}/#{user.id}"
        FileUtils.mv src, dest
        log_info("Success rename directory name from #{src} to #{dest}.")
      else
        log_warn("Failure rename directory(#{src}). Because user is not found that uid is #{uid}")
      end
    end
  end

  # 共有ファイルの実体ファイル配備ディレクトリgidをidに変換
  def self.rename_gid_dir
    group_base_path = "#{INITIAL_SETTINGS['share_file_path']}/group"
    return unless File.exist?(group_base_path)
    Dir.foreach(group_base_path) do |gid|
      next if (gid == '.' || gid == '..')
      if group = Group.find_by_gid(gid)
        src = "#{group_base_path}/#{gid}"
        dest = "#{group_base_path}/#{group.id}"
        FileUtils.mv src, dest
        log_info("Success rename directory name from #{src} to #{dest}.")
      else
        log_warn("Failure rename directory name from #{src} to #{dest}. Because group is not found that gid is #{gid}")
      end
    end
  end

  def self.new_share_file created_user_id, image_file_name
    return unless(image_attached_entry = image_attached_entry(image_file_name))
    share_file_name = share_file_name(image_file_name)
    extension = share_file_name.split('.').last.downcase
    share_file = ShareFile.new(
      # TODO file_nameにユニーク制限がかかっているので同名ファイル時の対策が必要
      :file_name => share_file_name,
      :description => '',
      :owner_symbol => image_attached_entry.symbol,
      :date => Time.now,
      :user_id => created_user_id,
      :content_type =>  "image/#{extension}",
      :publication_type => image_attached_entry.publication_type,
      :publication_symbols_value => image_attached_entry.publication_symbols_value
    )
    image_attached_entry.entry_publications.each do |entry_publication|
      share_file_publication = ShareFilePublication.new(:symbol => entry_publication.symbol)
      share_file.share_file_publications << share_file_publication
    end
    share_file
  end

  def self.share_file_name image_file_name
    image_file_name.split('_', 2).last
  end

  def self.image_attached_entry image_file_name
    BoardEntry.find_by_id(image_file_name.split('_', 2).first.to_i)
  end
end

MoveAttachmentImageToShareFile.execution(:argv => ARGV) unless RAILS_ENV == 'test'
