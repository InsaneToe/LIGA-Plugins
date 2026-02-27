#!/usr/bin/env node --no-warnings
/**
 * Copies SourceMod + MetaMod runtime files from generated/ into config/
 * so deployment packages contain a fully bootstrapped server addon setup.
 *
 * @module
 */
import fs from "node:fs";
import path from "node:path";

async function exists(filePath: string) {
  try {
    await fs.promises.access(filePath, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

async function copyRequired() {
  const root = process.cwd();
  const sourceRoot = path.join(root, "generated/csgo/addons");
  const destinationRoot = path.join(root, "config/csgo/addons");

  const requiredPaths = [
    { path: "metamod.vdf", overwrite: true },
    { path: "metamod", overwrite: true },
    { path: "sourcemod/bin", overwrite: true },
    // Keep repository-maintained configs such as `configs/core.cfg` intact.
    { path: "sourcemod/configs", overwrite: false },
    { path: "sourcemod/extensions", overwrite: true },
    { path: "sourcemod/gamedata", overwrite: true },
    { path: "sourcemod/translations", overwrite: true },
  ];

  const missing = [] as string[];

  for (const required of requiredPaths) {
    const relative = required.path;
    const from = path.join(sourceRoot, relative);
    const to = path.join(destinationRoot, relative);

    if (!(await exists(from))) {
      missing.push(from);
      continue;
    }

    await fs.promises.cp(from, to, {
      recursive: true,
      force: required.overwrite,
      errorOnExist: false,
    });
    console.info("Synced %s", path.relative(root, to));
  }

  if (missing.length > 0) {
    throw new Error(`Missing required runtime files:\n${missing.join("\n")}`);
  }
}

(async () => {
  try {
    await copyRequired();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
