  module SessionHelpers
  
  def sign_in(email, password)
    visit '/sessions/new'
    save_and_open_page
    fill_in 'email', :with => email
    fill_in 'password', :with => password
    click_button 'Sign in'
  end

end