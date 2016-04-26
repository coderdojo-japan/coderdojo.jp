class InstallScrivitoMigration < Scrivito::Migration
  def up
    Page.create(_path: '/', title: 'Welcome to Scrivito!', body: [
      HeadlineWidget.new(headline: 'A professional Cloud CMS built for Ruby on Rails.'),
      TextWidget.new(text: %{
        <h3>Add content management to your website</h3>
        <p>
        With Scrivito, you can develop your website like you always did.
        It just works, and it just works "The Rails Way".
        </p>
        <h3>No training for your editors required.</h3>
        <p>
        Your clients can edit content in-place, directly on the website itself.
        Intuitively, without any training or HTML skills.
        </p>
        <h3>No installation required</h3>
        <p>
        You should focus on the important things:
        Developing the functionality and look of your website.
        That's why we built Scrivito as a cloud service.
        So you don't have to keep on updating your CMS or worry about uptime all the time.
        And you always get the newest features.
        </p>
      })
    ])
  end
end
