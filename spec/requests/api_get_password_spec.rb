require 'rails_helper'

#TODO: review and rewrite all tests
describe "API Passwords" do
  # TODO: DRY with some factory_girl
  before do
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user << Group.new(name: "group for #{user.name}")}
    @groups.each_with_index {|group, i| group.authorize(@users[i])}
    @items = @groups.map {|group| group.add Item.new(username: "username for #{group.name}", password: "password for #{group.name}")}

    @root = Directory.create(name: 'root')
    @directories = 3.times.map { |i| Directory.root.mkdir! "dir#{i}", user: @users[i] }

    @subdirectories = @directories.map{ |dir| dir.mkdir!("subdir") }

    @items[0].directory = @directories[0]
    @items[1].directory = @directories[1]
    @items[2].directory = @directories[2]
    @items.each {|i| i.save!}
  end
  it "get a password with username and password with GET" do
    get "/_api/v1/_password/1?email=email0@example.com&password=password0"
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end
  it "not get the password of other with username and password with GET" do
    get "/_api/v1/_password/2?email=email0@example.com&password=password0"
    expect(response).not_to be_success
  end
  it "get a password with username and password with POST" do
    post "/_api/v1/_password/1", email: 'email0@example.com', password: 'password0'
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end
  it "get a password with http authentication" do
    e = env.merge({'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("email0@example.com", "password0") })
    get "/_api/v1/_password/1", {}, e
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end
  it "get a password with token" do
    get '/_api/v1/_authorize', email: "email0@example.com", password: "password0"
    token = response.body
    e = env.merge({"AUTHORIZATION" => "Token token=#{token}"})
    get "/_api/v1/_password/1", {}, e
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end
  it "get a password with token in cookie" do
    get '/_api/v1/_authorize', email: "email0@example.com", password: "password0"
    token = response.body
    e = env.merge({"Cookie" => "auth_token=#{token}"})
    #request.cookies[:auth_token] = token
    get "/_api/v1/_password/1", {}, e
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end
  it "but not with a bad token" do
    e = env.merge({"AUTHORIZATION" => "Token token=badtoken"})
    get "/_api/v1/_password/1", {}, e
    expect(response).not_to be_success
  end
  it "get a password with given path" do
    get '/_api/v1/_authorize', email: "email0@example.com", password: "password0"
    token = response.body
    e = env.merge({"AUTHORIZATION" => "Token token=#{token}"})
    get "/_api/v1/dir0/#{URI::escape('username for group for Name0')}", {}, e
    expect(response).to be_success
    expect(response.body).to eq 'password for group for Name0'
  end

  private
  def env
    {
      'Accept' => 'text/plain',
      'Content-Type' => 'text/plain'
    }
  end
end
