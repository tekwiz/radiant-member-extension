module SiteControllerMemberExtensions
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.class_eval do
      # alias_method_chain :show_page, :member_validation
      alias_method_chain :process_page, :set_current_member
      use_cookies_flash
      show_page_with_member_validation
    end
  end
  
  module ClassMethods
    def show_page_with_member_validation    
      around_filter do |controller, action|
        controller.send(:check_if_allowed)
        action.call
        controller.send(:do_not_cache)
      end
    end
  end
  
  module InstanceMethods
    def check_if_allowed
      if !MemberSystem.allow_url?(current_member, url)
        Radiant::Config["Member.need_login"].blank? ? flash[:notice] = "You must be logged in to access this page." : flash[:notice] = Radiant::Config["Member.need_login"]
        redirect_to MemberExtensionSettings.login_path
      end
    end
    
    def do_not_cache
      if url =~ Regexp.new(MemberExtensionSettings.root_path)
        expires_now
      end
    end
    
    def url
      url = params[:url]
      
      if Array === url
        url = url.join('/')
      else
        url = url.to_s
      end
      
      url
    end
    
    def process_page_with_set_current_member( page )
      page.current_member = current_member
      process_page_without_set_current_member(page)
    end
    
    # def show_page_with_member_validation
    #   url = params[:url]
    #   if Array === url
    #     url = url.join('/')
    #   else
    #     url = url.to_s
    #   end
    #   if MemberSystem.allow_url?(current_member, url)
    #     show_page_without_member_validation
    #     if url =~ Regexp.new(MemberExtensionSettings.root_path)
    #       expires_now
    #     end
    #   else
    #   Radiant::Config["Member.need_login"].blank? ? flash[:notice] = "You must be logged in to access this page." : flash[:notice] = Radiant::Config["Member.need_login"]
    #     redirect_to MemberExtensionSettings.login_path
    #   end
    # end
  end
end