**How to prioritize Code Rabbit and disable unwanted tools (workspace steps)**

- **1. Install Code Rabbit**: open the Extensions view and install the Code Rabbit extension. Replace the placeholder in `.vscode/extensions.json` (`REPLACE_WITH_CODE_RABBIT_EXTENSION_ID`) with the extension's identifier (publisher.name). Example: `publisher.code-rabbit`.
- **2. Add unwanted extensions**: put their extension IDs inside `unwantedRecommendations` in `.vscode/extensions.json` to signal they're not desired in this workspace.
- **3. Use the tasks**: run the tasks `Lint (fix) - backend` and `Test - backend` from the Run/Tasks menu to apply automatic fixes and run tests.
- **4. Auto-fix workflow**: the `backend` package.json now includes `npm run lint:fix` which runs `eslint --fix`. Use the task or `npm --prefix backend run lint:fix` to apply fixes.
- **5. Further automation**: if you want automated PR checks, add a CI workflow that runs `npm --prefix backend run lint:fix` and `npm --prefix backend test` on PRs.

If you want, tell me the exact Code Rabbit extension ID and a list of unwanted extension IDs and I will update `.vscode/extensions.json` for you and enable any sensible Code Rabbit settings if you provide them.
