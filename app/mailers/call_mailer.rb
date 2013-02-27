class CallMailer < ActionMailer::Base
  default from: "neurotelcal@neurotec.co"

  def message_email(to, content, plivocall = nil)
    @content = content
    @plivocall = plivocall
    mail(:to => to, :subject => 'Mensaje Automatico Neurotelcal')
  end
  
end
