class MembersController < ApplicationController
  include AuthenticatedMembersSystem
  
  no_login_required
  skip_before_filter :verify_authenticity_token
  before_filter :member_login_required
  
  use_cookies_flash
  
  def update
    @page = Page.find(params[:page_id])
    @page.request, @page.response = request, response

    if current_member.update_attributes(params[:member])
      flash[:notice] = 'Your information was successfully updated.'
      redirect_to (Radiant::Config['Member.succesful_member_update'] || "#{@page.url}#member_saved")
    else
      @page.current_member = current_member
      render :text => @page.render
    end
  end
end
