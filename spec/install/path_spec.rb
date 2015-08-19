require "spec_helper"

describe "bundle install" do
  describe "with `config path`" do
    before :each do
      build_gem "rack", "1.0.0", :to_system => true do |s|
        s.write "lib/rack.rb", "puts 'FAIL'"
      end

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "does not use available system gems with config path vendor/bundle" do
      bundle "config path vendor/bundle"
      bundle "install"
      should_be_installed "rack 1.0.0"
    end

    it "handles paths with regex characters in them" do
      dir = bundled_app("bun++dle")
      dir.mkpath

      Dir.chdir(dir) do
        bundle "config path vendor/bundle"
        bundle "install"
        expect(out).to include("installed into ./vendor/bundle")
      end

      dir.rmtree
    end

    it "prints a warning to let the user know what has happened with config path vendor/bundle" do
      bundle "config path vendor/bundle"
      bundle "install"
      expect(out).to include("gems are installed into ./vendor")
    end

    it "disallows config path vendor/bundle and install system" do
      bundle "config path vendor/bundle"
      bundle "install --system"
      expect(err).to include("Please use only one.")
    end

    it "remembers to disable system gems after config path vendor/bundle" do
      bundle "config path vendor/bundle"
      bundle "install"
      FileUtils.rm_rf bundled_app("vendor")
      bundle "install"

      expect(vendored_gems("gems/rack-1.0.0")).to be_directory
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when BUNDLE_PATH or the global path config is set" do
    before :each do
      build_lib "rack", "1.0.0", :to_system => true do |s|
        s.write "lib/rack.rb", "raise 'FAIL'"
      end

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    def set_bundle_path(type, location)
      if type == :env
        ENV["BUNDLE_PATH"] = location
      elsif type == :global
        bundle "config path #{location}", "no-color" => nil
      end
    end

    [:env, :global].each do |type|
      it "installs gems to a path if one is specified" do
        set_bundle_path(type, bundled_app("vendor2").to_s)
        # NOTE: This spec fails if we don't specify a scope or if we use --global.
        # The precedence order is local -> env -> global: see Settings#[] (lib/bundler/settings.rb:L19).
        bundle "config --local path vendor/bundle"
        bundle "install"

        expect(vendored_gems("gems/rack-1.0.0")).to be_directory
        expect(bundled_app("vendor2")).not_to be_directory
        should_be_installed "rack 1.0.0"
      end

      it "installs gems to BUNDLE_PATH with #{type}" do
        set_bundle_path(type, bundled_app("vendor").to_s)

        bundle :install
        expect(bundled_app("vendor/#{Bundler.ruby_scope}/gems/rack-1.0.0")).to be_directory
        should_be_installed "rack 1.0.0"
      end

      it "installs gems to BUNDLE_PATH relative to root when relative" do
        bundle "config path vendor"
        # set_bundle_path(type, bundled_app("vendor").to_s)

        FileUtils.mkdir_p bundled_app("lol")
        Dir.chdir(bundled_app("lol")) do
          bundle :install
        end

        expect(bundled_app("vendor/#{Bundler.ruby_scope}/gems/rack-1.0.0")).to be_directory
        should_be_installed "rack 1.0.0"
      end
    end

    it "installs gems to BUNDLE_PATH from .bundle/config" do
      config "BUNDLE_PATH" => bundled_app("vendor/bundle").to_s

      bundle :install

      expect(vendored_gems("gems/rack-1.0.0")).to be_directory
      should_be_installed "rack 1.0.0"
    end

    it "sets BUNDLE_PATH as the first argument to bundle install" do
      bundle "config path ./vendor/bundle"
      bundle "install"

      expect(vendored_gems("gems/rack-1.0.0")).to be_directory
      should_be_installed "rack 1.0.0"
    end

    it "disables system gems when passing a path to install" do
      # This is so that vendored gems can be distributed to others
      build_gem "rack", "1.1.0", :to_system => true
      bundle "config path ./vendor/bundle"
      bundle "install"

      expect(vendored_gems("gems/rack-1.0.0")).to be_directory
      should_be_installed "rack 1.0.0"
    end
  end

  describe "to a dead symlink" do
    before do
      in_app_root do
        `ln -s /tmp/idontexist bundle`
      end
    end

    it "reports the symlink is dead" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      # NOTE: This spec fails if we don't specify a scope or if we use --global.
      bundle "config --local path bundle"
      bundle "install"

      expect(err).to match(/invalid symlink/)
    end
  end
end
