require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile install with git sources" do
  describe "when floating on master" do
    before :each do
      in_app_root

      build_git "foo"

      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}"
        gem 'foo'
      G
    end

    it "fetches gems" do
      should_be_installed("foo 1.0")

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end

    it "floats on master if no ref is specified" do
      update_git "foo"

      in_app_root2 do
        install_gemfile bundled_app2("Gemfile"), <<-G
          git "#{lib_path('foo-1.0')}"
          gem 'foo'
        G
      end

      in_app_root do
        run <<-RUBY
          require 'foo'
          puts "WIN" if defined?(FOO_PREV_REF)
        RUBY

        out.should == "WIN"
      end
    end
  end

  describe "when specifying a revision" do
    it "works" do
      in_app_root

      build_git "foo"
      @revision = revision_for(lib_path("foo-1.0"))
      update_git "foo"

      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}", :ref => "#{@revision}"
        gem "foo"
      G

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end
  end
end