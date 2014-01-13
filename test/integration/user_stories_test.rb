require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest

  fixtures :products

  # user buying a product
  test "buying a product" do
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)

    # user goes to store index page
    get "/"
    assert_response :success
    assert_template "index"

    # user selects a product
    xml_http_request :post, '/line_items', product_id: ruby_book.product_id
    assert_response :success

    # adding it to their cart
    cart = Cart.find(session[:cart_id])
    assert_equal l, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product

    # user checks out
    get "/orders/new"
    assert_response :success
    assert_template "new"

    # when user submits, an order is created containing its information
    post_via_redirect "/orders",
                      order: { name:    "Dave Thomas",
                               address: "123 The Street",
                               email:   "dave@example.com",
                               pay_type:"Check" }
    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size

    # order is created in the database with correct details
    orders = Order.all
    assert_equal 1, orders.size
    order = orders[0]

    assert_equal "Dave Thomas",     order.name
    assert_equal "123 The Street",  order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check",           order.pay_type

    assert_equal 1l, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product

    # verify that mail correctly addressed and has the expected subject line
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
    assert_equal 'Pragmatic Store Order Confirmation', mail.subject
  end
end



