# frozen_string_literal: true
require 'test_helper'

if defined?(::Rails::Railtie) && defined?(::ActionView)
  class ActionViewExtensionTest < ActionView::TestCase
    setup do
      self.output_buffer = ::ActionView::OutputBuffer.new
      I18n.available_locales = [:en, :de, :fr]
      I18n.locale = :en
    end
    teardown do
      User.delete_all
    end
    sub_test_case '#paginate' do
      setup do
        50.times {|i| User.create! name: "user#{i}"}
      end

      test 'returns a String' do
        users = User.page(1)
        assert_kind_of String, view.paginate(users, params: {controller: 'users', action: 'index'})
      end

      test 'escaping the pagination for javascript' do
        users = User.page(1)
        assert_nothing_raised do
          escape_javascript(view.paginate users, params: {controller: 'users', action: 'index'})
        end
      end

      test 'allows for overriding params with the :params option' do
        view.params[:controller], view.params[:action] = 'addresses', 'new'
        users = User.page(1)

        assert_match '/users?page=2', view.paginate(users, params: { controller: 'users', action: 'index' })
      end

      test 'accepts :theme option' do
        users = User.page(1)
        begin
          controller.append_view_path File.join(Gem.loaded_specs['kaminari-core'].gem_dir, 'test/fake_app/views')

          html = view.paginate users, theme: 'bootstrap', params: {controller: 'users', action: 'index'}
          assert_match(/bootstrap-paginator/, html)
          assert_match(/bootstrap-page-link/, html)
        ensure
          controller.view_paths.pop
        end
      end

      test 'accepts :views_prefix option' do
        users = User.page(1)
        begin
          controller.append_view_path File.join(Gem.loaded_specs['kaminari-core'].gem_dir, 'test/fake_app/views')

          assert_equal "  <b>1</b>\n", view.paginate(users, views_prefix: 'alternative/', params: {controller: 'users', action: 'index'})
        ensure
          controller.view_paths.pop
        end
      end

      test 'accepts :paginator_class option' do
        users = User.page(1)
        custom_paginator = Class.new(Kaminari::Helpers::Paginator) do
          def to_s
            "CUSTOM PAGINATION"
          end
        end

        assert_equal 'CUSTOM PAGINATION', view.paginate(users, paginator_class: custom_paginator, params: {controller: 'users', action: 'index'})
      end

      test 'total_pages: 3' do
        users = User.page(1)
        assert_match(/<a href="\/users\?page=3">Last/, view.paginate(users, total_pages: 3, params: {controller: 'users', action: 'index'}))
      end

      test "page: 20 (out of range)" do
        users = User.page(20)

        html = view.paginate users, params: {controller: 'users', action: 'index'}
        assert_not_match(/Last/, html)
        assert_not_match(/Next/, html)
      end
    end

  end
end
