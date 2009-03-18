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

class BatchSendCleaningNotification < BatchBase
  def self.execute options
    sender = self.new
    sender.send_cleaning_notification
  end

  def send_cleaning_notification
    if Admin::Setting.enable_user_cleaning_notification
      now = Time.now
      if now.month % Admin::Setting.user_cleaning_notification_interval == 0 && now.day == 1
        UserMailer.deliver_sent_cleaning_notification cleaning_notification_to_addresses
      end
    end
  end

  private
  def cleaning_notification_to_addresses
    Admin::User.admin.active.map { |u| u.email }.join(',')
  end
end

BatchSendMails.execution unless RAILS_ENV == 'test'