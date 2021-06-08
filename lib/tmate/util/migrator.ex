require Logger

defmodule Tmate.DbMigrator do
  def migrate do
    Logger.info("Tmate.DbMigrator started")
    path = Application.app_dir(:tmate, "priv/repo/migrations")
    Logger.debug("Performing migration from directory #{path}")
    Ecto.Migrator.run(Tmate.Repo, path, :up, all: true)
    Logger.info("Tmate.DbMigrator finished")
  end
end