module MemberTags
  
  include Radiant::Taggable
  
  tag 'member' do |tag|
    tag.expand
  end
  
  desc %{
    Renders the login link taking into acount the @member_login_path@ setting from Radiant::Config. Use the @text@ attribute to control the text in the link. The default is "Login".
    
    *Usage*:
    <pre><code><r:member:login [text="Come on in!"] /></code></pre>
  }
  tag 'member:login' do |tag|
    text = tag.attr['text'] || 'Login'
    %{<a href="#{MemberExtensionSettings.login_path}">#{text}</a>}
  end
  
  desc %{
    Renders the logout link. Use the @text@ attribute to control the text in the link. The default is "Logout".
    
    *Usage*:
    <pre><code><r:member:logout [text="Get out!"] /></code></pre>
  }
  tag 'member:logout' do |tag|
    text = tag.attr['text'] || 'Logout'
    %{<a href="#{MemberExtensionSettings.defaults[:logout_path]}">#{text}</a>}
  end
  
  desc %{
    Renders the link where the member will be redirected after logging in, taking into acount the @member_home_path@ setting from Radiant::Config. Use the @text@ attribute to control the text in the link. The default is "Members Home".
    
    *Usage*:
    <pre><code><r:member:home [text="Members Home!"] /></code></pre>
  }
  tag 'member:home' do |tag|
    text = tag.attr['text'] || 'Members Home'
    %{<a href="#{MemberExtensionSettings.home_path}">#{text}</a>}
  end
  
  desc %{
    Renders the link to the node under which the pages will be restricted, taking into acount the @member_root@ setting from Radiant::Config. Use the @text@ attribute to control the text in the link. The default is "Members Home".
    
    *Usage*:
    <pre><code><r:member:root [text="Members Root!"] /></code></pre>
  }
  tag 'member:root' do |tag|
    text = tag.attr['text'] || 'Root'
    %{<a href="#{MemberExtensionSettings.root_path}">#{text}</a>}
  end
  
  desc %{
    Use this tag as action for the login form.
    
    *Usage*:
    <pre><code><r:member:sessions /></code></pre>
  }
  tag 'member:sessions' do |tag|
    "#{MemberExtensionSettings.defaults[:sessions_path]}"
  end

  desc %{
    Use this tag to include the javascripts for the flash boxes
    
    *Usage*:
    <pre><code><r:member:javascripts /></code></pre>
  }
  tag 'member:javascripts' do |tag|
    member_javascript_includes
  end
  
  ### deprecated
  desc %{DEPRECATED... see <code><r:member:javascripts /></code>}
  tag 'member_javascripts' do |tag|
    RAILS_DEFAULT_LOGGER.warn 'DEPRECATION WARNING: `r:member_javascripts` called (will be removed in next version)... This is changed to `r:member:javascripts`'
    member_javascript_includes
  end
  
  ##
  # Member Update Form
  ##
  desc %{
    Creates a form to modify the current member's information.
    
    *Usage*:
    <pre><code><r:member:form [id="update-member-form"] [class=""]></r:member:form></code></pre>
  }
  tag 'member:form' do |tag|
    tag.attr['id'] ||= 'update-member-form'
    results = [ %(<form action="/pages/#{tag.locals.page.id}/update_member" method="post"#{extra_attrs(tag, 'id', 'class')}>) ]
    results << tag.expand
    results << %(</form>)
  end
  
  # Text fields & labels
  {'name' => 'text', 'email' => 'text', 'password' => 'password', 'password_confirmation' => 'password'}.each do |field,type|
    tag "member:#{field}_field" do |tag|
      tag.attr['id'] ||= "member_#{field}"
      tag.attr['value'] = tag.locals.page.current_member.send(field.to_sym) if type == 'text'
      %(<input name="member[#{field}]" type="#{type}"#{extra_attrs(tag, 'id', 'class', 'value')} />)
    end
    
    tag "member:#{field}_label" do |tag|
      tag.attr['for'] ||= "member_#{field}"
      txt = tag.expand
      %(<label#{extra_attrs(tag, 'for', 'id', 'class')}>#{txt.blank? ? field.titleize : txt}</label>)
    end
  end
  
  # Error Messages
  tag "member:if_error" do |tag|
    return if (member = tag.locals.page.current_member).nil? || member.valid?
    if (on = tag.attr['on']) && (errors = member.errors[on.to_sym])
      tag.locals.error_messages = (errors.is_a?(String) ? [errors] : errors)
      tag.expand
    elsif (tag.attr['on'] == 'all')
      tag.locals.error_messages = member.errors.full_messages
      tag.expand
    elsif tag.attr['on'].nil?
      errors = member.errors.on_base
      tag.locals.error_messages = (errors.is_a?(String) ? [errors] : errors) 
      tag.expand
    end
  end
  
  tag "member:errors" do |tag|
    tag.expand
  end
  
  tag "member:errors:each" do |tag|
    r = []
    tag.locals.error_messages.each do |m|
      tag.locals.message = m
      r << tag.expand
    end
    return r
  end
  
  tag "member:errors:message" do |tag|
    tag.locals.message
  end
  
protected

  def extra_attrs( tag, *keys)
    keys.collect {|k| %( #{k}="#{tag.attr[k]}") unless tag.attr[k].blank?}.join
  end
  
  def member_javascript_includes
    %(<script type="text/javascript" src="/javascripts/jquery.cookies.2.1.0.min.js"></script>
      <script type="text/javascript" src="/javascripts/jquery.json-2.1.min.js"></script>
      <script type="text/javascript" src="/javascripts/flash-box.js"></script>)
  end
end
