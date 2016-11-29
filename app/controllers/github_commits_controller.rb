class GithubCommitsController < ApplicationController
  unloadable
  skip_before_filter :verify_authenticity_token

  def create_comment
    if params[:commits].present? && verify_signature?
      last_commit = params[:commits].first
      message = last_commit[:message]
      if message.present? && message.include?("rm_issue #")
        issue_id = message[(message.index("rm_issue #(")+11)..(message.index(")")-1)].to_i
        issue = Issue.find_by(id: issue_id)
      end
      email = EmailAddress.find_by(address: last_commit[:author][:email])
      user = email.present? ? email.user : User.where(admin: true).first
        
      if last_commit.present? && issue.present?
        message.sub! issue_id.to_s, "Issue ##{issue_id}"
        notes = "Commit On Github with message: " + message + "  \"View on GitHub\":" + last_commit[:url]
        issue.journals.create(journalized_id: issue_id, journalized_type: "Issue", user: user, notes: notes)
      end
    end
    render nothing: true, status: :ok
  end

  def verify_signature?
    request.body.rewind
    payload_body = request.body.read
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret_token, payload_body)
    return Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end
