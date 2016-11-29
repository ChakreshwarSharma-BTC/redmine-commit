class GithubCommitsController < ApplicationController
  unloadable
  skip_before_filter :verify_authenticity_token, :only => [:create_comment]
  def create_comment
    if params[:commits].present?
      project = Project.find_by(identifier: params[:project_id])
      last_commit = params[:commits].first
      message = last_commit[:message]
      issue_id = message[(message.index("issue #(")+8)..(message.index(")")-1)].to_i
      issue = Issue.find_by id: issue_id
      email = EmailAddress.find_by(address: last_commit[:author][:email])
      user_id = email.present? ? email.user.id : User.where(admin: true).first.id
        
      if project.present? && last_commit.present? && issue.present?
        notes = "Commit On Github with message: " + message + "  \"ViewOnGithub\":" + last_commit[:url]
        issue.journals.create(journalized_id: issue_id, journalized_type: "Issue", user_id: user_id, notes: notes)
      end
    end
  end
end
