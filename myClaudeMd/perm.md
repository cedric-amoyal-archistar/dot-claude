Use the team of agents to plan, show me plan and then execute using the team of agents. ( mode: "acceptEdits" )

Analyse carefully:
- /Users/cedricamoyal/.claude/settings.json
As well as project specific:
- /Users/cedricamoyal/.claude/.claude/settings.local.json
- /Users/cedricamoyal/dev/archistar/frontend/citymanager/client/.claude/settings.local.json
- /Users/cedricamoyal/dev/archistar/frontend/start-frontend/client/.claude/settings.local.json
- /Users/cedricamoyal/dev/archistar/frontend/portal-frontend/.claude/settings.local.json


I want to add more items in the allow list globally so only update /Users/cedricamoyal/.claude/settings.json
Claude code is asking again and again for the same permissions that seems to common and not risky.
So Claude should not ask for permissions for:
- read only commands
- commands that are updating files tracked in git (do not commit or push)

Let me know what the best practices are.
Write a plan with the team
You can see above example of projects specific settings.local.json, not sure if they are correct but if we setup things globally in /Users/cedricamoyal/.claude/settings.json it should be used everywhere?
Is the local file or the global file winning? Can you explain with different case scenarios?