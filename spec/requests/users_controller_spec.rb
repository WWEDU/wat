# -*- encoding : utf-8 -*-

require File::expand_path('../../spec_helper', __FILE__)
require 'capybara/rspec'

describe UsersController do
  
  describe "With an admin and temporary users" do
    before(:each) do
      User.delete_all
      Identity.delete_all
      visit root_path
      visit switch_language_path(:en)
      sign_up_user name: 'Testuser', password: 'notsecret', email: 'test@iboard.cc'
      user = User.first
      user.email_confirmed_at =  Time.now
      user.facilities.create name: 'Admin', access: 'rwx'
      user.save!
    end
   
    it "should login user" do
       sign_in_user name: 'Testuser', password: 'notsecret'
       visit users_path
       page.click_link "You"
       page.should have_content "Testuser"
    end
  
    it "should have add- and remove authentication buttons" do
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit "/users/testuser"
      page.should have_link "Twitter"
      page.should have_link "Facebook"
      page.should have_link "Remove"
    end
  
    it "should have a delete-button" do
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit users_path
      page.should have_link "Cancel Account" 
      visit "/users/testuser"
      page.should have_link "Cancel Account" 
    end
  
    it "should delete user" do
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit users_path
      page.click_link "Cancel Account" 
      visit users_path
      page.should have_no_content "Testuser"
    end

    it "should display a message if an exeptions raised on user.destroy" do
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit users_path
      class User
        def delete
          raise "DON'T DELETE ME WHILE TESTING"
        end
        def destroy
          raise "DON'T DESTROY ME WHILE TESTING"
        end
      end
      page.click_link "Cancel Account" 
      page.should have_content "ERROR: DON'T DESTROY ME WHILE TESTING"
    end
  
    it "shows facilities in user-show view" do
      User.first.facilities.create name: 'Admin', access: 'rwx'
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit user_path(User.first)
      page.should have_content "Facilities: Admin"
    end
  
    it "shows facilities in user-list" do
      User.first.facilities.find_or_create_by name: 'Admin', access: 'rwx'
      sign_in_user name: 'Testuser', password: 'notsecret'
      visit users_path
      page.should have_content "Facilities: Admin"
    end
  
    it "should not show foreign users unless current_user is admin" do
      visit signout_path
      User.create  name: 'Foreigner', email: 'alien@iboard.cc'
      sign_up_user name: 'Hacker', password: 'notsecret', email: 'hacked@iboard.cc'    
      visit users_path
      page.should_not have_content "Foreigner"
      page.should have_content "Access denied"
    end
  
    it "sends a confirmation mail when a user is created" do
      visit signout_path
      sign_up_user name: "Friendly User", password: 'notsecret', email: 'newuser@iboard.cc'
      last_email.to.should include('newuser@iboard.cc')
    end
  
    it "sends a confirmation mail when the email changes" do
      visit signout_path
      sign_up_user name: "Friendly User", password: 'notsecret', email: 'user@iboard.cc'
      click_link "Edit"
      fill_in "Email", with: "user1@iboard.cc"
      click_button "Save"
      last_email.to.should include('user1@iboard.cc')
    end
  
    it "checks email confirmed" do
      visit signout_path
      User.delete_all
      sign_up_user name: "Friendly User", password: 'notsecret', email: 'user@iboard.cc'
      user = User.first
      assert user.email_confirmed? == false, "email_confirmed? should be false"
      visit confirm_email_user_path(user,user.confirm_email_token)
      user.reload
      assert user.email_confirmed? == true, "email_confirmed? should be true after confirming it"
    end

    it "shows a message if user doesn't confirm their email yet" do
      visit signout_path
      User.delete_all
      sign_up_user name: "Friendly User", password: 'notsecret', email: 'user@iboard.cc'
      visit signout_path
      sign_in_user name: "Friendly User", password: 'notsecret'
      page.should have_content "Your email is not confirmed by now. Please check your mailbox for user@iboard.cc."
      page.should have_link "Resend confirmation mail"
    end
  
    it "adds an Identity to an existing user" do
      visit signout_path
      @twitteruser = User.create name: 'Twitter User', email: 'twitter@example.com'
      @twitteruser.authentications.create provider: "twitter", uid: "1345"
      set_current_user(@twitteruser)
      visit new_identity_path
      fill_in "password", with: "ABCdefg"
      fill_in "password_confirmation", with: "ABCdefg"
      click_button "Register"
      page.should have_content "Provider identity added to your account."
      unset_current_user
      sign_in_user name: "Twitter User", password: 'ABCdefg'
      page.should have_content "Signed in"
    end
  end

  describe "For a standard user with identity" do

    before(:each) do
      User.delete_all
      Identity.delete_all
      visit signout_path
      visit switch_language_path(:en)
      sign_up_user name: 'Mr. Standard', password: "Mr. Nice", email: "standard@example.com"
      @user1 = User.where(name: 'Mr. Standard').first
    end

    it "shows connected auth_providers" do
      visit user_path(@user1)
      page.should have_link "Assign authentication providers"
      page.should have_link "Personal information"
    end
  
    it "switches personal information and authentication providers", :js => true, :driver => :webkit do
      visit user_path(@user1)
      click_link 'Personal information'
      page.should have_content "No personal information stored yet"
      click_link 'Assign authentication providers'
      page.should have_content "Identity"
    end
  end
  
  describe "as an admin" do
    before(:each) do
      User.delete_all
      Identity.delete_all
      visit switch_language_path(:en)
      sign_up_user name: "Admin", password: 'notsecret', email: 'admin@iboard.cc'
      @admin = User.first
      @confirmed_at = Time.now
      @admin.email_confirmed_at = @confirmed_at
      @admin.facilities.create name: 'Admin', access: 'rwx'
      @admin.save!
    end

    it "shows the confirmation status in user::index" do
      visit users_path
      page.should have_content "Email confirmed at: #{I18n.localize(@confirmed_at)}"
      page.should have_content "Account exists since #{I18n.localize(@admin.created_at)}"
    end

    it "finds users using the search-form without JS" do
      User.create name: "Hidden user", email: "hidden@example.com"
      visit users_path
      fill_in 'search_search_text', with: "admi"
      click_button "Search"
      page.should have_content "Admin"
      page.should_not have_content "Hidden user"
    end

    it "finds users using the search-form with JS", js: true do
      User.create name: "Find Me", email: "find@me.com"
      set_current_user @admin
      visit users_path
      fill_in 'search_search_text', with: "find"
      page.should_not have_button "Search"
      page.should have_content "Find Me"
      page.should_not have_content "admin@iboard.cc"
    end

  end

end
