module Smsway
  module EventHandler
    def ticket_created
      return true unless settings.notify_ticket_created.to_s = '1'
      sent_ticket_sms(payload.ticket)
    end

    def customer_reply_created
      return true unless settings.notify_customer_reply_created.to_s == '1'
      reply = payload.reply
      sent_reply_sms(payload.ticket, payload.reply)
    end

    def agent_reply_created
      return true unless settings.notify_agent_reply_created.to_s == '1'
      sent_reply_sms(payload.ticket, payload.reply)
    end

    def comment_created
      return true unless settings.notify_comment_created.to_s == '1'
      sent_comment_sms(payload.ticket, payload.comment)
    end
  end
end

module Smsway
  module ActionHandler
    def button
      #Handle button 
      [200, "Success"]
    end
  end
end

module Smsway
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Sent.ly Username', :hint => "Signup for a Sent.ly account at https://sent.ly/"
    password :password, :required => true, :label => 'Sent.ly Password', :hint => "Sent.ly password"
    string :number, :required => true, :label => 'Mobile no', :hint => "Mobile no with country code"
    boolean :notify_ticket_created, :default => true, :label => 'Sms when a Ticket is created'
    boolean :notify_agent_reply_created, :default => false, :label => 'Sms when an Agent replies'
    boolean :notify_customer_reply_created, :default => false, :label => 'Sms when a Customer replies'
    boolean :notify_comment_created, :default => false, :label => 'Sms when a Comment is created'

    white_list :notify_ticket_created

    def sent_ticket_sms(ticket)
      message = "New ticket from #{ticket.requester.name || ticket.requester.email} - #{ticket.subject}"
      http_post "http://sent.ly/command/sendsms" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:to]       = "+#{settings.number}"
        req.params[:text]     = message[0...160]
      end
    end

    def sent_reply_sms(ticket, reply)
      message = "New reply from #{reply.replier.name || reply.replier.email} in #{ticket.subject}"
      http_post "http://sent.ly/command/sendsms" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:to]       = "+#{settings.number}"
        req.params[:text]     = message[0...160]
      end
    end

    def sent_comment_sms(ticket, comment)
      message = "New comment from #{comment.commenter.name || comment.commenter.email} in #{ticket.subject}"
      http_post "http://sent.ly/command/sendsms" do |req|
        req.params[:username] = settings.username
        req.params[:password] = settings.password
        req.params[:to]       = "+#{settings.number}"
        req.params[:text]     = message[0...160]
      end
    end

  end
end

