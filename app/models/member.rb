require 'digest/sha1'

class Member < ActiveRecord::Base
  cattr_accessor :email_name_regex, :domain_head_regex, :domain_tld_regex, :email_regex, :name_regex
  
  self.email_name_regex  = '[\w\.%\+\-]+'.freeze
  self.domain_head_regex = '(?:[A-Z0-9\-]+\.)+'.freeze
  self.domain_tld_regex  = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'.freeze
  self.email_regex       = /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
  self.name_regex        = /\A[^[:cntrl:]\\<>\/&]*\z/
  
  validates_uniqueness_of   :email,    :allow_blank => true
  validates_format_of       :email,    :allow_blank => true, :with => email_regex

  # validates_presence_of     :first_name, :last_name
  # validates_format_of       :first_name, :last_name,     :with => name_regex

  attr_accessor :password, :password_confirmation
  validates_confirmation_of :password, :if => :password_required?

  before_save :encrypt_password
  after_create :email_new_password

  %w{name email}.each do |s|
    named_scope :"by_#{s}", lambda{ |search_term| {:conditions => ["LOWER(#{s}) LIKE ?", "%#{search_term.to_s.downcase}%"]}}
  end
  
  SORT_COLUMNS = ['name', 'email', 'emailed_at']

  def self.members_paginate(params)
    options = {
      :page => params[:page],
      :per_page => 10,
    }
    if SORT_COLUMNS.include?(params[:sort_by]) && %w(asc desc).include?(params[:sort_order])
      options[:order] = "#{params[:sort_by]} #{params[:sort_order]}"
    end
    params.reject { |k, v| [:page, :sort_by, :sort_order].include?(k) }.
      inject(Member) { |scope, pair| pair[1].blank? ? scope : scope.send(:"by_#{pair[0]}", pair[1]) }.
      paginate(options)
  end
  
  def self.import_members(file, options = {})
    imported = 0
    duplicate = 0
    @not_valid = []
    members_from_csv = FasterCSV.parse(file, :headers => true)
    
    members_from_csv.each do |m|
      fields = [:nl_mailed, :list_serv_removal, :first_name, :last_name, :street, :city, :state, :zip, :paid, 
        :notes, :dob, :lettered, :home, :work, :cell, :fax, :email, :email_2, :occupation, :spouse]
      h = {}
      fields.each_index { |i| h[fields[i]] = m[i] }
      member = self.new(h)
      if options[:activate]
        member.password = member.password_confirmation = make_token[0..6]
      end
      if member.save
        imported = imported + 1
      else
        if member.errors.on(:email) == "has already been taken"
          duplicate = duplicate + 1
        else
          @not_valid << [m[0], m[1], member.errors.full_messages.join(', ')]
        end
      end
    end
    [imported, duplicate, @not_valid]
  end
  
  def self.update_invalid_members(params)
    imported = 0
    @not_valid = []
    
    params.each do |m|
      member = self.new(m)
      if member.save
        imported = imported + 1
      else
        @not_valid << [m[:name], m[:email], member.errors.full_messages.join(', ')]
      end      
    end
    [imported, @not_valid]
  end
  
  def self.secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  
  def self.make_token
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
  
  def activate!
    return false if self.email.blank?
    if self.disabled_password.blank?
      email_new_password("Your account has been activated.", :force_new => true)
    else
      self.crypted_password = disabled_password
      self.save
    end
  end
  
  def deactivate!
    self.disabled_password = crypted_password
    self.crypted_password = nil
    self.save
  end

  def self.authenticate(email, password)
    return nil if email.blank? || password.blank?
    m = find(:first, :conditions => ['email = ?', email] ) # need to get the salt
    m && m.authenticated?(password) ? m : nil
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def email_new_password(message = 'Your account has been created.', options = {})
    return true if self.email.blank?
    if options[:force_new] || self.password.blank?
      self.password = self.password_confirmation = self.class.make_token[0..6]
    end
    MemberMailer.deliver_password_email(self, message)
    self.emailed_at = Time.now
    self.save
  end
  
  def remember_me
    remember_me_for 2.weeks
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def refresh_token
    if remember_token?
      self.remember_token = self.class.make_token 
      save(false)      
    end
  end
  
  def name
    ((first_name || '') + ' ' + (last_name || '')).strip
  end
  
  def emailable?
    not email.blank?
  end
  
protected
  def encrypt_password
    return if password.blank?
    self.salt = self.class.make_token if new_record?
    self.crypted_password = encrypt(password)
  end
  
  def encrypt(password)
    password_digest(password, salt)
  end
  
  def password_digest(password, salt)
    digest = MemberExtensionSettings.rest_auth_site_key
    MemberExtensionSettings.rest_auth_digest_stretches.times do
      digest = self.class.secure_digest(digest, salt, password, MemberExtensionSettings.rest_auth_site_key)
    end
    digest
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def remember_token?
    (!remember_token.blank?) && 
      remember_token_expires_at && (Time.now.utc < remember_token_expires_at.utc)
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = self.class.make_token
    save(false)
  end
end
