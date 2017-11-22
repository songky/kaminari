# frozen_string_literal: true
require 'test_helper'

class PaginatorHelperTest < ActiveSupport::TestCase
  class UrlHelperImpl
    include Kaminari::Helpers::UrlHelper

    include Rails.application.routes.url_helpers # implements #url_for
    attr_accessor :params                        # implements #params

    # implements #controller (used by #url_for under the hood)
    def controller
      params[:controller]
    end
  end

  class TagHelperImpl
    include Kaminari::Helpers::TagHelper

    include ActionView::Helpers::UrlHelper       # implements #link_to
    include Rails.application.routes.url_helpers # implements #url_for
    attr_accessor :params                        # implements #params

    # implements #controller (used by #url_for under the hood)
    def controller
      params[:controller]
    end
  end

  attr_reader :helper

  sub_test_case '#link_to_previous_page' do
    setup do
      @helper = TagHelperImpl.new
      @helper.params = { controller: 'users', action: 'index' }

      60.times {|i| User.create! name: "user#{i}" }
    end

    sub_test_case 'having previous pages' do
      test 'the default behaviour' do

        users = User.page(3)
        html = helper.link_to_previous_page users, 'Previous'
        assert_match(/page=2/, html)
        assert_match(/rel="prev"/, html)

        html = helper.link_to_previous_page(users, 'Previous') { 'At the Beginning' }
        assert_match(/page=2/, html)
        assert_match(/rel="prev"/, html)
      end

      test 'overriding rel=' do
        users = User.page(3)
        assert_match(/rel="external"/, helper.link_to_previous_page(users, 'Previous', rel: 'external'))
      end

      test 'with params' do
        users = User.page(3)
        helper.params[:status] = 'active'

        assert_match(/status=active/, helper.link_to_previous_page(users, 'Previous'))
      end
    end

    test 'the first page' do
      users = User.page(1)

      assert_nil helper.link_to_previous_page(users, 'Previous')
      assert_equal 'At the Beginning', (helper.link_to_previous_page(users, 'Previous') { 'At the Beginning' })
    end

    test 'out of range' do
      users = User.page(5)

      assert_nil helper.link_to_previous_page(users, 'Previous')
      assert_equal 'At the Beginning', (helper.link_to_previous_page(users, 'Previous') { 'At the Beginning' })
    end

    test '#link_to_previous_page accepts ActionController::Parameters' do
      users = User.page(3)
      helper.params = ActionController::Parameters.new(controller: 'users', action: 'index', status: 'active')

      html = helper.link_to_previous_page users, 'Previous'

      assert_match(/page=2/, html)
      assert_match(/rel="prev"/, html)
      assert_match(/status=active/, html)
    end
  end

  sub_test_case '#link_to_next_page' do
    setup do
      @helper = TagHelperImpl.new
      @helper.params = { controller: 'users', action: 'index' }

      50.times {|i| User.create! name: "user#{i}"}
    end

    sub_test_case 'having more page' do
      test 'the default behaviour' do
        users = User.page(1)
        html = helper.link_to_next_page users, 'More'

        assert_match(/page=2/, html)
        assert_match(/rel="next"/, html)
      end

      test 'overriding rel=' do
        users = User.page(1)

        assert_match(/rel="external"/, helper.link_to_next_page(users, 'More', rel: 'external'))
      end

      test 'with params' do
        users = User.page(1)
        helper.params[:status] = 'active'

        assert_match(/status=active/, helper.link_to_next_page(users, 'More'))
      end
    end

    test 'the last page' do
      users = User.page(2)

      assert_nil helper.link_to_next_page(users, 'More')
    end

    test 'out of range' do
      users = User.page(5)

      assert_nil helper.link_to_next_page(users, 'More')
    end

    test '#link_to_next_page accepts ActionController::Parameters' do
      users = User.page(1)
      helper.params = ActionController::Parameters.new(controller: 'users', action: 'index', status: 'active')

      html = helper.link_to_next_page users, 'More'

      assert_match(/page=2/, html)
      assert_match(/rel="next"/, html)
      assert_match(/status=active/, html)
    end
  end

  sub_test_case '#page_entries_info' do
    setup do
      @helper = Class.new { include Kaminari::Helpers::ViewHeler }.new
    end

    sub_test_case 'on a model without namespace' do
      sub_test_case 'having no entries' do
        test 'with default entry name' do
          users = User.page(1).per(25)
          assert_equal 'No users found', helper.page_entries_info(users)
        end

        test 'setting the entry name option to "member"' do
          users = User.page(1).per(25)
          assert_equal 'No members found', helper.page_entries_info(users, entry_name: 'member')
        end
      end

      sub_test_case 'having 1 entry' do
        setup do
          User.create! name: 'user1'
        end

        test 'with default entry name' do
          users = User.page(1).per(25)
          assert_equal 'Displaying <b>1</b> user', helper.page_entries_info(users)
        end

        test 'setting the entry name option to "member"' do
          users = User.page(1).per(25)
          assert_equal 'Displaying <b>1</b> member', helper.page_entries_info(users, entry_name: 'member')
        end
      end

      sub_test_case 'having more than 1 but less than a page of entries' do
        setup do
          10.times {|i| User.create! name: "user#{i}"}
        end

        test 'with default entry name' do
          users = User.page(1).per(25)
          assert_equal 'Displaying <b>all 10</b> users', helper.page_entries_info(users)
        end

        test 'setting the entry name option to "member"' do
          users = User.page(1).per(25)
          assert_equal 'Displaying <b>all 10</b> members', helper.page_entries_info(users, entry_name: 'member')
        end
      end

      sub_test_case 'having more than one page of entries' do
        setup do
          50.times {|i| User.create! name: "user#{i}"}
        end

        sub_test_case 'the first page' do
          test 'with default entry name' do
            users = User.page(1).per(25)
            assert_equal 'Displaying users <b>1&nbsp;-&nbsp;25</b> of <b>50</b> in total', helper.page_entries_info(users)
          end

          test 'setting the entry name option to "member"' do
            users = User.page(1).per(25)
            assert_equal 'Displaying members <b>1&nbsp;-&nbsp;25</b> of <b>50</b> in total', helper.page_entries_info(users, entry_name: 'member')
          end
        end

        sub_test_case 'the next page' do
          test 'with default entry name' do
            users = User.page(2).per(25)
            assert_equal 'Displaying users <b>26&nbsp;-&nbsp;50</b> of <b>50</b> in total', helper.page_entries_info(users)
          end

          test 'setting the entry name option to "member"' do
            users = User.page(2).per(25)
            assert_equal 'Displaying members <b>26&nbsp;-&nbsp;50</b> of <b>50</b> in total', helper.page_entries_info(users, entry_name: 'member')
          end
        end

        sub_test_case 'the last page' do
          test 'with default entry name' do
            begin
              User.max_pages 4
              users = User.page(4).per(10)

              assert_equal 'Displaying users <b>31&nbsp;-&nbsp;40</b> of <b>50</b> in total', helper.page_entries_info(users)
            ensure
              User.max_pages nil
            end
          end
        end
      end
    end

    sub_test_case 'I18n' do
      setup do
        50.times {|i| User.create! name: "user#{i}"}
      end

      test 'page_entries_info translates entry' do
        users = User.page(1).per(25)
        begin
          I18n.backend.store_translations(:en, User.i18n_scope => { models: { user: { one: "person", other: "people" } } })

          assert_equal 'Displaying people <b>1&nbsp;-&nbsp;25</b> of <b>50</b> in total', helper.page_entries_info(users)
        ensure
          I18n.backend.reload!
        end
      end

      sub_test_case 'with any other locale' do
        teardown do
          I18n.backend.reload!
        end

        sub_test_case ':de' do
          setup do
            @org_locale, I18n.locale = I18n.locale, :de
            I18n.backend.store_translations(:de, helpers: {
              page_entries_info: {
                one_page: {
                  display_entries: {
                    one: "Displaying <b>1</b> %{entry_name}",
                    other: "Displaying <b>all %{count}</b> %{entry_name}"
                  }
                },
                more_pages: {
                  display_entries: "Displaying %{entry_name} <b>%{first}&nbsp;-&nbsp;%{last}</b> of <b>%{total}</b> in total"
                }
              }
            })
          end

          teardown do
            I18n.locale = @org_locale
          end

          test 'with default entry name' do
            users = User.page(1).per(50)
            assert_equal 'Displaying <b>all 50</b> Benutzer', helper.page_entries_info(users,  entry_name: 'Benutzer')
          end

          test 'the last page with default entry name' do
            User.max_pages 4
            users = User.page(4).per(10)
            assert_equal 'Displaying Benutzer <b>31&nbsp;-&nbsp;40</b> of <b>50</b> in total', helper.page_entries_info(users,  entry_name: 'Benutzer')
          end
        end
      end

      sub_test_case ':fr' do
        setup do
          @org_locale, I18n.locale = I18n.locale, :fr
          ActiveSupport::Inflector.inflections(:fr) do |inflect|
            inflect.plural(/$/, 's')
            inflect.singular(/s$/, '')
          end
          I18n.backend.store_translations(:fr, helpers: {
            page_entries_info: {
              one_page: {
                display_entries: {
                  one: "Displaying <b>1</b> %{entry_name}",
                  other: "Displaying <b>all %{count}</b> %{entry_name}"
                }
              },
              more_pages: {
                display_entries: "Displaying %{entry_name} <b>%{first}&nbsp;-&nbsp;%{last}</b> of <b>%{total}</b> in total"
              }
            }
          })
        end

        teardown do
          I18n.locale = @org_locale
        end

        sub_test_case 'having 1 entry' do
          setup do
            User.delete_all
            User.create! name: 'user1'
          end

          test 'with default entry name' do
            users = User.page(1).per(25)
            assert_equal 'Displaying <b>1</b> utilisateur', helper.page_entries_info(users,  entry_name: 'utilisateur')
          end
        end

        test 'having multiple entries with default entry name' do
          users = User.page(1).per(50)
          assert_equal 'Displaying <b>all 50</b> utilisateurs', helper.page_entries_info(users,  entry_name: 'utilisateur')
        end

        test 'the last page with default entry name' do
          User.max_pages 4
          users = User.page(4).per(10)
          assert_equal 'Displaying utilisateurs <b>31&nbsp;-&nbsp;40</b> of <b>50</b> in total', helper.page_entries_info(users,  entry_name: 'utilisateur')
        end
      end
    end

    sub_test_case 'on a model with namespace' do
      teardown do
        User::Address.delete_all
      end

      test 'having no entries' do
        addresses = User::Address.page(1).per(25)
        assert_equal 'No addresses found', helper.page_entries_info(addresses)
      end

      sub_test_case 'having 1 entry' do
        setup do
          User::Address.create!
        end

        test 'with default entry name' do
          addresses = User::Address.page(1).per(25)
          assert_equal 'Displaying <b>1</b> address', helper.page_entries_info(addresses)
        end

        test 'setting the entry name option to "place"' do
          addresses = User::Address.page(1).per(25)
          assert_equal 'Displaying <b>1</b> place', helper.page_entries_info(addresses, entry_name: 'place')
        end
      end

      sub_test_case 'having more than 1 but less than a page of entries' do
        setup do
          10.times { User::Address.create! }
        end

        test 'with default entry name' do
          addresses = User::Address.page(1).per(25)
          assert_equal 'Displaying <b>all 10</b> addresses', helper.page_entries_info(addresses)
        end

        test 'setting the entry name option to "place"' do
          addresses = User::Address.page(1).per(25)
          assert_equal 'Displaying <b>all 10</b> places', helper.page_entries_info(addresses, entry_name: 'place')
        end
      end

      sub_test_case 'having more than one page of entries' do
        setup do
          50.times { User::Address.create! }
        end

        sub_test_case 'the first page' do
          test 'with default entry name' do
            addresses = User::Address.page(1).per(25)
            assert_equal 'Displaying addresses <b>1&nbsp;-&nbsp;25</b> of <b>50</b> in total', helper.page_entries_info(addresses)
          end

          test 'setting the entry name option to "place"' do
            addresses = User::Address.page(1).per(25)
            assert_equal 'Displaying places <b>1&nbsp;-&nbsp;25</b> of <b>50</b> in total', helper.page_entries_info(addresses, entry_name: 'place')
          end
        end

        sub_test_case 'the next page' do
          test 'with default entry name' do
            addresses = User::Address.page(2).per(25)
            assert_equal 'Displaying addresses <b>26&nbsp;-&nbsp;50</b> of <b>50</b> in total', helper.page_entries_info(addresses)
          end

          test 'setting the entry name option to "place"' do
            addresses = User::Address.page(2).per(25)
            assert_equal 'Displaying places <b>26&nbsp;-&nbsp;50</b> of <b>50</b> in total', helper.page_entries_info(addresses, entry_name: 'place')
          end
        end
      end
    end

    test 'on a PaginatableArray' do
      numbers = Kaminari.paginate_array(%w{one two three}).page(1)

      assert_equal 'Displaying <b>all 3</b> entries', helper.page_entries_info(numbers)
    end
  end

  sub_test_case '#rel_next_prev_link_tags' do
    setup do
      @helper = TagHelperImpl.new
      @helper.params = { controller: 'users', action: 'index' }

      31.times {|i| User.create! name: "user#{i}"}
    end

    test 'the first page' do
      users = User.page(1).per(10)
      html = helper.rel_next_prev_link_tags users

      assert_not_match(/rel="prev"/, html)
      assert_match(/rel="next"/, html)
      assert_match(/\?page=2/, html)
    end

    test 'the second page' do
      users = User.page(2).per(10)
      html = helper.rel_next_prev_link_tags users

      assert_match(/rel="prev"/, html)
      assert_not_match(/\?page=1/, html)
      assert_match(/rel="next"/, html)
      assert_match(/\?page=3/, html)
    end

    test 'the last page' do
      users = User.page(4).per(10)
      html = helper.rel_next_prev_link_tags users

      assert_match(/rel="prev"/, html)
      assert_match(/\?page=3"/, html)
      assert_not_match(/rel="next"/, html)
    end
  end

  sub_test_case '#path_to_next_page' do
    setup do
      @helper = TagHelperImpl.new
      @helper.params = { controller: 'users', action: 'index' }

      2.times {|i| User.create! name: "user#{i}"}
    end

    test 'the first page' do
      users = User.page(1).per(1)
      assert_equal '/users?page=2', helper.path_to_next_page(users)
    end

    test 'the last page' do
      users = User.page(2).per(1)
      assert_nil helper.path_to_next_page(users)
    end
  end

  sub_test_case '#path_to_prev_page' do
    setup do
      @helper = TagHelperImpl.new
      @helper.params = { controller: 'users', action: 'index' }

      3.times {|i| User.create! name: "user#{i}"}
    end

    test 'the first page' do
      users = User.page(1).per(1)
      assert_nil helper.path_to_prev_page(users)
    end

    test 'the second page' do
      users = User.page(2).per(1)
      assert_equal '/users', helper.path_to_prev_page(users)
    end

    test 'the last page' do
      users = User.page(3).per(1)
      assert_equal'/users?page=2', helper.path_to_prev_page(users)
    end
  end
end
