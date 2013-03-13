#encoding: utf-8

require 'spec_helper'

feature "use #t" do

  it "the dummy app has a translation for site.index.header but not site.index.intro" do
    I18n.t('site.index.header').should == 'The Header'
    I18n.t('site.index.intro').should == "translation missing: en.site.index.intro"
  end

  it "uses i18n.t" do
    visit root_path
    page.should have_content 'The Header'
    page.should have_content 'Intro' #ActionView::Helpers::TranslationHelper#translate wrapper
  end

  it "creates a copycat_translation if the yaml has an entry" do
    CopycatTranslation.find_by_key('site.index.header').should be_nil
    visit root_path
    CopycatTranslation.find_by_key('site.index.header').should_not be_nil
  end

  it "creates a copycat_translation if the yaml does not have an entry" do
    CopycatTranslation.find_by_key('site.index.intro').should be_nil
    visit root_path
    CopycatTranslation.find_by_key('site.index.intro').should_not be_nil
  end

  it "shows the copycat_translation instead of the yaml" do
    FactoryGirl.create(:copycat_translation, key: 'site.index.header', value: 'A different header')
    visit root_path
    page.should_not have_content 'The Header'
    page.should have_content 'A different header'
  end

  it "allows to treat every translation as html safe" do
    FactoryGirl.create(:copycat_translation, key: 'site.index.header', value: '<strong>Strong header</strong>')
    visit root_path
    page.should have_content '<strong>Strong header</strong>'
    Copycat.everything_is_html_safe = true
    visit root_path
    page.should_not have_content '<strong>Strong header</strong>'
    page.should have_content 'Strong header'
  end
end

feature "locales" do

  it "displays different text based on users' locale" do
    FactoryGirl.create(:copycat_translation, locale: 'en', key: 'site.index.intro', value: 'world')
    FactoryGirl.create(:copycat_translation, locale: 'es', key: 'site.index.intro', value: 'mundo')

    I18n.locale = :en
    visit root_path
    page.should have_content 'world'
    page.should_not have_content 'mundo'

    I18n.locale = :es
    visit root_path
    page.should have_content 'mundo'
    page.should_not have_content 'world'

    I18n.locale = :fa
    visit root_path
    page.should_not have_content 'world'
    page.should_not have_content 'mundo'

    I18n.locale = :en  # reset
  end

end

feature "yaml" do

  it "round-trips both translations correctly (and doesn't export nils)" do
    visit root_path
    CopycatTranslation.find_by_key('site.index.intro').value.should be_nil
    CopycatTranslation.find_by_key('site.index.header').value.should == 'The Header'
    CopycatTranslation.count.should == 2

    page.driver.browser.basic_authorize Copycat.username, Copycat.password
    visit import_export_copycat_translations_path
    click_link 'Download as YAML'
    CopycatTranslation.destroy_all
    CopycatTranslation.count.should == 0
    yaml = page.source
    file = Tempfile.new 'copycat'
    file.write yaml
    file.close
    visit import_export_copycat_translations_path
    attach_file "file", file.path
    click_button "Upload"
    file.unlink

    CopycatTranslation.count.should == 1
    CopycatTranslation.find_by_key('site.index.intro').should be_nil
    CopycatTranslation.find_by_key('site.index.header').value.should == 'The Header'
  end

end

feature "automatic deployment" do
  before do
    page.driver.browser.basic_authorize Copycat.username, Copycat.password
  end

  it "shouldn't show the syncing button if no staging_server_endpoint is set" do
    visit import_export_copycat_translations_path
    page.should_not have_content('Sync from staging server')
  end

  it "shouldn't show the syncing button in staging" do
    Copycat.staging_server_endpoint = "nothing"

    Rails.env = "staging"
    visit import_export_copycat_translations_path
    page.should_not have_content('Sync from staging server')

    %w[production development test].each do |env|
      Rails.env = env
      visit import_export_copycat_translations_path
      page.should have_content('Sync from staging server')
    end
  end

  it "should allow to sync translations from the source server when it is set" do
    Copycat.staging_server_endpoint = "nothing"
    CopycatTranslationsController.any_instance.stub(:read_remote_yaml).and_return <<-EOF
---
es:
  first_key: "Primera clave"
  second_key: "Segunda clave"
en:
  first_key: "First key"
  second_key: "Second key"
  third_key: "Third key"
EOF

    visit import_export_copycat_translations_path

    click_link 'Sync from staging server'

    page.should have_content('Translations synced from source server')

    CopycatTranslation.find_all_by_key('first_key').count.should eq(2)
    CopycatTranslation.find_all_by_key('second_key').count.should eq(2)
    CopycatTranslation.find_all_by_key('third_key').count.should eq(1)
  end
end