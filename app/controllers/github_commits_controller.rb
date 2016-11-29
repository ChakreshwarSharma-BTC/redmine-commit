class GithubCommitsController < ApplicationController
  unloadable
skip_before_filter :verify_authenticity_token
  def create_comment
    if params[:commits].present? && verify_signature?
      project = Project.find_by(identifier: params[:project_id])
      last_commit = params[:commits].first
      message = last_commit[:message]
      issue_id = message[(message.index("rm_issue #(")+8)..(message.index(")")-1)].to_i
      issue = Issue.find_by id: issue_id
      email = EmailAddress.find_by(address: last_commit[:author][:email])
      user_id = email.present? ? email.user.id : User.where(admin: true).first.id
        
      if project.present? && last_commit.present? && issue.present?
        notes = "Commit On Github with message: " + message + "  \"ViewOnGithub\":" + last_commit[:url]
        issue.journals.create(journalized_id: issue_id, journalized_type: "Issue", user_id: user_id, notes: notes)
      end
    end
  end

  def verify_signature?
    request.body.rewind
    payload_body = request.body.read
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret_token, payload_body)
    return Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end
