class MemberMailer < ActionMailer::Base
  def password_email(member, message)
    setup_email(member)
    @body[:message] = message
  end
  
  protected
    def setup_email(member)
      @recipients  = "#{member.email}"
      @from        = Radiant::Config['Member.email.from'] || "no_reply@site.ro"
      @subject     = Radiant::Config['Member.email.subject'] || "Your Account"
      @sent_on     = Time.now
      @body[:member] = member
    end
end
