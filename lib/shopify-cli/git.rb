module ShopifyCli
  ##
  # ShopifyCli::Git wraps git functionality to make it easier to integrate will
  # git.
  class Git
    class << self
      ##
      # will return the current sha of the cli repo
      #
      # #### Parameters
      #
      # * `dir` - the directory of the git repo. This defaults to the cli repo
      # * `ctx` - the current running context of your command
      #
      # #### Returns
      #
      # * `sha_string` - string of the sha of the most recent commit to the repo
      #
      # #### Example
      #
      #   ShopifyCli::Git.sha
      #
      def sha(dir: Dir.pwd, ctx: Context.new)
        rev_parse("HEAD", dir: dir, ctx: ctx)
      end

      ##
      # will make calls to git to clone a new repo into a supplied destination,
      # it will also output progress of the cloning process.
      #
      # #### Parameters
      #
      # * `repository` - a git url for git to clone the repo from
      # * `dest` - a filepath to where the repo should be cloned to
      # * `ctx` - the current running context of your command, defaults to a new context.
      #
      # #### Returns
      #
      # * `sha_string` - string of the sha of the most recent commit to the repo
      #
      # #### Example
      #
      #   ShopifyCli::Git.clone('git@github.com:shopify/test.git', 'test-app')
      #
      def clone(repository, dest, ctx: Context.new)
        if Dir.exist?(dest)
          ctx.abort(ctx.message("core.git.error.directory_exists"))
        else
          success_message = ctx.message("core.git.cloned", dest)
          CLI::UI::Frame.open(ctx.message("core.git.cloning", repository, dest), success_text: success_message) do
            clone_progress("clone", "--single-branch", repository, dest, ctx: ctx)
          end
        end
      end

      ##
      # will fetch the repos list of branches.
      #
      # #### Parameters
      #
      # * `ctx` - the current running context of your command, defaults to a new context.
      #
      # #### Returns
      #
      # * `branches` - [String] an array of strings that are branch names
      #
      # #### Example
      #
      #   branches = ShopifyCli::Git.branches(@ctx)
      #
      def branches(ctx)
        output, status = ctx.capture2e("git", "branch", "--list", "--format=%(refname:short)")
        ctx.abort(ctx.message("core.git.error.no_branches_found")) unless status.success?

        branches = if output == ""
          ["master"]
        else
          output.split("\n")
        end

        branches
      end

      ##
      # will initialize a new repo in the current directory. This will output
      # if it was successful or not.
      #
      # #### Parameters
      #
      # * `ctx` - the current running context of your command, defaults to a new context.
      #
      # #### Example
      #
      #   ShopifyCli::Git.init(@ctx)
      #
      def init(ctx)
        output, status = ctx.capture2e("git", "status")

        unless status.success?
          ctx.abort(ctx.message("core.git.error.repo_not_initiated"))
        end

        if output.include?("No commits yet")
          ctx.abort(ctx.message("core.git.error.no_commits_made"))
        end
      end

      private

      def exec(*args, dir: Dir.pwd, default: nil, ctx: Context.new)
        args = %w(git) + ["--git-dir", File.join(dir, ".git")] + args
        out, _, stat = ctx.capture3(*args)
        return default unless stat.success?
        out.chomp
      end

      def rev_parse(*args, dir: nil, ctx: Context.new)
        exec("rev-parse", *args, dir: dir, ctx: ctx)
      end

      def clone_progress(*git_command, ctx:)
        CLI::UI::Progress.progress do |bar|
          msg = []
          require "open3"

          success = Open3.popen3("git", *git_command, "--progress") do |_stdin, _stdout, stderr, thread|
            while (line = stderr.gets)
              msg << line.chomp
              next unless line.strip.start_with?("Receiving objects:")
              percent = (line.match(/Receiving objects:\s+(\d+)/)[1].to_f / 100).round(2)
              bar.tick(set_percent: percent)
              next
            end

            thread.value
          end.success?

          ctx.abort(msg.join("\n")) unless success
          bar.tick(set_percent: 1.0)
          success
        end
      end
    end
  end
end
