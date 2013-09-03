# Copycat [![Build Status](https://travis-ci.org/Zorros/copycat.png)](https://travis-ci.org/Zorros/copycat) [![Code Climate](https://codeclimate.com/github/Zorros/copycat.png)](https://codeclimate.com/github/Zorros/copycat)#

Copycat is a Rails engine that allows users to edit live website copy.

## How to use this gem as a translator / copywriter ##

This is the advised way on how a translator could use copycat to translate a Rails app. Note that the gem is not written for translators, rather for developers, but with a little of effort it's fairly easy to understand how it all works. Ask your developer if doubts.

* You will (or should) have a testing and a production environment of your Rails application.
* Ideally, you never do translations directly on production. You do them in test, and then import them into production. The reason is that in some cases, a wrong translation might result in an error. You want to discover errors on test, and not on your production system.
* On your test system, access the URL http://your-test-application.com/copycat_translations or /translations (ask the path to your developer)
* When you access that URL, you will be asked a user and password (get it from the developer)
* Once connected, the page shows a language drop down, and a search box
* Select your language and search for a text that you want to change/translate
* If the translation is already in place, but you want to change it, then search for the text you want to change. For example, if you want to change a button called "Save" to "Save now", then search for the text "Save" in the search box. Make sure to select the right language first.
* If you want to see the whole dictionary of a given language, leave the search field empty, and click "search". You will see all translations.
* Alternatively, you can search for the "dictionary key" or just "key" of the translation. Each key is unique in the dictionary. (Texts are not unique - you can have a lot of buttons called "save“).
* If the translation is not yet in place, Ruby on Rails will show on the public page what the key is. This is done by uppercasing the key, and removing all _ signs from it. For example, a key called "sign_up_button" that is not yet translated, will be shown as "Sign Up Button" in the web. When you hover over the word with your mouse (in your web application), RoR will show a tooltip with the key.
* In that case, you should search for the key to find the translation.
* Once you have found your key or your text, just click it, and change it.
* You see your changes directly in your test system.
* Once all translations and copy is OK in the test system, they can be imported / migrated to the production system.
* On production, you have a /copycat_translations path, password secured, that allows you to IMPORT all translations from the test system at once. Just log on to production, and click "synch", it will overwrite ALL production translations with the translations on test (!!!including the ones that you did not change!!!).
* Alternatively, the path on production could be closed (for security reasons), and you write your own import / migration script. Ask your developer about this.
* BUT I WANT TO EXPOT/IMPORT FROM EXCEL, HOW CAN I DO THAT? If you want to mass-download, mass-translate, and mass-upload translations, we recommend to install http://www.activeadmin.info/ - this gem allows to search, download, filter, upload, ... RoR tables via online web interface.
* WHY ARE THERE SO MANY EMPTY KEYS IN THE DICTIONARY? DO I NEED TO FILL THEM IN? Rails uses a smart inheritance mechanism. You can use the empty keys to overwrite certain defaults. For example, Rails will call a button to save a user "Save user", just because it makes sense by default. However, there will be an empty key associated with this, that you can use to overwrite the standard rails behavior. You don't need to fill in this key. You could. It's up to you. The advised way to do all translations is to start from the screens, and not from the dictionary. So don't worry about empty keys, just look at all of the screens one by one, and translate / change what is not correct. Don't worry about empty keys.

## How to use ##

Add ```copycat``` to your Gemfile and run ```bundle install```.

Copycat uses a database table to store the copy items, and so it is necessary to create that:

```
rake copycat:install
rake db:migrate
```

Since Copycat data is stored locally on an indexed table with no foreign keys, page loads are very fast and changes appear instantly.

In a view, use the Rails i18n translate method where you would like to display some editable copy:


```erb
<h1><%= t('site.index.header') %></h1>
```

Visit the page in your browser, and a Copycat translation will be created for the key. Then visit `/copycat_translations` in your browser, log in with the username and password generated in `config/initializers/copycat.rb`, and you can edit the value of that token.

## Rails i18n API ##

You can read about the Rails internationalization framework [here](http://guides.rubyonrails.org/i18n.html).

## Deploying ##

To transfer changes from staging to production:

* Download copy as YAML on staging
* Login to Copycat on production
* Upload YAML to production

Since this process requires no code commits, non-developers can also 'deploy' copy changes.

You can also commit Copycat's YAML export, which is compatible with i18n, to your git repository.

## Routes ##

The default route to edit copy is '/copycat_translations'. This can be customized in the initializer.

The Copycat routes are configured automatically by the engine, after your Rails application's routes.rb file is run. This means that if your routes include a catchall route at the bottom, the Copycat route will be masked. In this case you can manually draw the Copycat routes prior to the catchall route with the following line in config/routes.rb:

```ruby
Rails.application.routes.draw do
  Copycat.routes(self)
end
```

## Logging ##
Because Copycat does a SQL query for each token, it can produce a lot of noise in the log output.
Therefore by default the logger is disabled for the Copycat ActiveRecord class.
It can be enabled with the environment variable COPYCAT_DEBUG, e.g.

```bash
COPYCAT_DEBUG=1 rails s
```

## Example ##

See an example application [here](https://github.com/Vermonster/copycat-demo). 

## Developing ##

As a Rails engine, Copycat is developed using a nested dummy Rails app. After cloning the repository and running bundler, the plugin must be installed in the dummy app:

```
bundle
cd spec/dummy
rake copycat:install
rake db:create db:migrate db:test:prepare
cd ../..
```

Now you can run the test suite:

```
rspec spec/
```

## License ##

Copycat is released under the MIT license. See MIT-LICENSE file.
