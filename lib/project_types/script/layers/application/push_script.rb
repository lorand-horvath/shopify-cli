# frozen_string_literal: true

module Script
  module Layers
    module Application
      class PushScript
        class << self
          def call(ctx:, force:)
            script_project_repo = Infrastructure::ScriptProjectRepository.new(ctx: ctx)
            script_project = script_project_repo.get
            task_runner = Infrastructure::Languages::TaskRunner
              .for(ctx, script_project.language, script_project.script_name)

            ProjectDependencies.install(ctx: ctx, task_runner: task_runner)
            BuildScript.call(ctx: ctx, task_runner: task_runner, script_project: script_project)

            UI::PrintingSpinner.spin(ctx, ctx.message("script.application.pushing")) do |p_ctx, spinner|
              package = Infrastructure::PushPackageRepository.new(ctx: p_ctx).get_push_package(
                script_project: script_project,
                compiled_type: task_runner.compiled_type,
                metadata: task_runner.metadata,
              )
              script_service = Infrastructure::ScriptService.new(ctx: p_ctx, api_key: script_project.api_key)
              module_upload_url = Infrastructure::ScriptUploader.new(script_service).upload(package.script_content)
              uuid = script_service.set_app_script(
                uuid: package.uuid,
                extension_point_type: package.extension_point_type,
                force: force,
                metadata: package.metadata,
                script_json: package.script_json,
                module_upload_url: module_upload_url,
              )
              script_project_repo.update_env(uuid: uuid)
              spinner.update_title(p_ctx.message("script.application.pushed"))
            end
          end
        end
      end
    end
  end
end
