module Bigcommerce
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      http.basic_auth(settings.username, settings.api_token)

      begin
        api = connect_to_bigcommerce
        
        if api
          orders = get_orders(api)
          html = order_info_html(orders)
          sent_note_to_customer(ticket, orders)
        else
          return [500, "Ticket not sent. Unable to connect to Bigcommerce"]
        end

      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end

      comment_on_ticket(ticket, html)
      [200, "Ticket sent to Bigcommerce"]
    end
  end
end

module Bigcommerce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Enter User Name', :hint => 'See how to create an api user and get the token in "https://support.bigcommerce.com/questions/1560/How+do+I+enable+the+API+for+my+store%3F"'
    string :api_token, :required => true, :label => 'Enter Api Token'
    string :subdomain, :required => true, :label => 'Enter Subdomain',  :hint => 'If your Shop URL is "https://store-bwvr466.mybigcommerce.com/api/v2/" then your Subdomain value is "store-bwvr466"'
     
    white_list :subdomain

    def connect_to_bigcommerce
      api = Bigcommerce::Api.new({
      :store_url => settings.shop_url,
      :username  => settings.username,
      :api_key   => settings.api_token
      })
    end

    def get_orders(api)
      begin
        orders = api.get_orders
      rescue RuntimeError => e
        puts "#{e.message}\n#{e.backtrace}"
      end
    end

    def sent_note_to_customer(ticket, orders)
      order = orders.last
      http.put "https://#{settings.subdomain}.mybigcommerce.com/api/v2/customers/#{order['customer_id']}.json" do |req|
        req.headers['Content-Type'] = "application/json"
        req.body= {notes:generate_note(ticket)}.to_json
      end
    end

    def generate_note(ticket)
      "[Support Ticket] https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def order_info_html(orders)
      order = orders.last
      order_items = get_ordered_items(order)
      items_html = order_items_html(order_items)
      date = DateTime.parse(order['date_created'])
      formatted_date = date.strftime('%a %b %d %H:%M:%S')
      html = ""
      html << "<h3>Order Details"
      html << "<p>Order Count: #{orders.count}"
      html << "<p>Ordered Items:"
      html << items_html
      html << "<p><p><table>"
      html << "<tr><th><h5>Status:"
      html << "</th><th><h5>Subtotal:"
      html << "</th><th><h5>Total:"
      html << "</th><th><h5>Date Created:"
      html << "</th></tr><tr><td>#{order['status']}"
      html << "</td><td>#{order['subtotal_inc_tax'].to_f}"
      html << "</td><td>#{order['total_inc_tax'].to_f}"
      html << "</td><td>#{formatted_date}"
      html << "</td></tr>"
      html << "</table>"
      html << ">>" + order_info_link(order)
      html
    end

    def order_info_link(order)
      "<a href='https://#{settings.subdomain}.mybigcommerce.com/admin/index.php?ToDo=viewOrder&orderId=#{order['id']}'>View Order Info</a>"
    end

    def get_ordered_items(order)
      url = order['products']['url']
      response = http.get "#{url}" do |req|
        req.params['Accept'] = "application/json"
      end
      order_items = response.body if response
    end

    def order_items_html(order_items)
      html = ""
      if order_items.kind_of?(Array)
        order_items.select{|item| html << "<br/><h5 style=\"font-weight:normal\">#{item['name']}"} 
      else 
        html << "<br/><h5 style=\"font-weight:normal\">#{order_items['name']}" if order_items
      end
      return html
    end
  
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end
