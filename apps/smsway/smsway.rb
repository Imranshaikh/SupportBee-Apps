module Smsway
  module EventHandler
    def ticket_created
      begin
        sent_sms
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Sms sent successfully via Sent.ly"]

    end      
  end
end

module Smsway
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Smsway
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Sent.ly Username'
    password :password, :required => true, :label => 'Sent.ly Password'
    string :to, :required => true, :label => 'Mobile No.'
    string :text, :required => true, :label => 'Message'
    
    white_list :username, :password, :to, :text


    def sent_sms
      
      http_post "http://sent.ly/command/sendsms" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:to]       = "+#{settings.to}"
        req.params[:text]     = settings.text
      end

    end

  end
end

